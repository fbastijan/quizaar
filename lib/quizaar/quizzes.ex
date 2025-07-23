defmodule Quizaar.Quizzes do
  @moduledoc """
  The Quizzes context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Quizaar.Repo

  alias Quizaar.Quizzes.Quiz

  @doc """
  Returns the list of quizzes.

  ## Examples

      iex> list_quizzes()
      [%Quiz{}, ...]

  """
  def list_quizzes do
    Repo.all(Quiz)
  end

  @doc """
  Gets a single quiz.

  Raises `Ecto.NoResultsError` if the Quiz does not exist.

  ## Examples

      iex> get_quiz!(123)
      %Quiz{}

      iex> get_quiz!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quiz!(id), do: Repo.get!(Quiz, id)

  @doc """
  Gets a single quiz by its code.
  Raises `Ecto.NoResultsError` if the Quiz does not exist.
  ## Examples

      iex> get_quiz_by_code!("quiz_code")
      %Quiz{}

      iex> get_quiz_by_code!("invalid_code")
      ** (Ecto.NoResultsError)

  """
  def get_quiz_by_code(join_code), do: Repo.get_by(Quiz, join_code: join_code)

  @doc """
  Creates a quiz.

  ## Examples

      iex> create_quiz(%{field: value})
      {:ok, %Quiz{}}

      iex> create_quiz(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quiz(attrs \\ %{}) do
    %Quiz{}
    |> Quiz.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quiz.

  ## Examples

      iex> update_quiz(quiz, %{field: new_value})
      {:ok, %Quiz{}}

      iex> update_quiz(quiz, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quiz(%Quiz{} = quiz, attrs) do
    quiz
    |> Quiz.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quiz.

  ## Examples

      iex> delete_quiz(quiz)
      {:ok, %Quiz{}}

      iex> delete_quiz(quiz)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quiz(%Quiz{} = quiz) do
    Repo.delete(quiz)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quiz changes.

  ## Examples

      iex> change_quiz(quiz)
      %Ecto.Changeset{data: %Quiz{}}

  """
  def change_quiz(%Quiz{} = quiz, attrs \\ %{}) do
    Quiz.changeset(quiz, attrs)
  end

  alias Quizaar.Quizzes.Question

  @doc """
  Returns the list of questions.

  ## Examples

      iex> list_questions()
      [%Question{}, ...]

  """
  def list_questions do
    Repo.all(Question)
  end

  @doc """
  Gets a single question.

  Raises `Ecto.NoResultsError` if the Question does not exist.

  ## Examples

      iex> get_question!(123)
      %Question{}

      iex> get_question!(456)
      ** (Ecto.NoResultsError)

  """
  def get_question!(id), do: Repo.get!(Question, id)
  def get_question(id), do: Repo.get(Question, id)

  def get_questions_by_quiz_id(quiz_id) do
    Repo.all(from q in Question, where: q.quiz_id == ^quiz_id)
  end

  @doc """
  Creates a question.

  ## Examples

      iex> create_question(%{field: value})
      {:ok, %Question{}}

      iex> create_question(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_question(attrs \\ %{}) do
    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  @api_url "https://api.groq.com/openai/v1/chat/completions"
  # Ensure the API key is set in your environment variables
  @doc """
  Sends a prompt, using POST, to a large language model (LLM) and returns the generated response.

  ## Parameters

    - `prompt` (String): The input text or question to be sent to the LLM.
    - `opts` (Keyword list, optional): Additional options for the query, such as model parameters or configuration.

  ## Returns

    - `{:ok, response}` on success, where `response` is the LLM's generated output.
    - `{:error, reason}` on failure.

  ## Examples

      iex> query_llm("What is Elixir?")
      {:ok, "Elixir is a dynamic, functional language designed for building scalable and maintainable applications."}
  """
  def query_llm(prompt) do
    headers = [
      {"Content-Type", "application/json"},
      # Ensure the API key is set in your environment variables
      {"Authorization", "Bearer #{System.get_env("GROQ_API_KEY")  |> String.trim()}"},
      {"Accept", "application/json"}
    ]

    body =
      %{
        "model" => "meta-llama/llama-4-maverick-17b-128e-instruct",
        "response_format" => %{type: "json_object"},
        "temperature" => 0.6,
        "messages" => [
          %{
            "role" => "user",
            "content" => prompt
          }
        ]
      }
      |> Jason.encode!()

    request = Finch.build(:post, @api_url, headers, body)

    case Finch.request(request, Quizaar.Finch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, decoded_body} -> {:ok, decoded_body}
          {:error, decode_error} ->
            IO.inspect(decode_error, label: "Error occurred")
            {:error, {:decode_error, decode_error}}

        end

      {:ok, %Finch.Response{status: status_code, body: error_body}} ->
        IO.inspect(error_body, label: "Error response body")

        {:error, {:http_error, status_code, error_body}}

      {:error, reason} ->
        IO.inspect(reason, label: "Request error")
        {:error, {:request_error, reason}}
    end
  end

  @doc """
    Reads a prompt from a file and returns the user's input.
    This function reads a prompt from a specified file and parses it into string format.


  ## Examples

    iex> read_prompt("Lib/Prompt1.txt")
    {:ok, "Alice"}
    iex> read_prompt("Lib/Prompt2.txt")
    {:ok, "Bob"}
    "Alice"

  ## Parameters

    - `prompt`: A string to display as the prompt message.

  ## Returns

    - `{:ok, content}` on success, where `content` is the parsed prompt.
    - `{:error, reason}` on failure.
  """
  def read_prompt(filename) do
      path = Path.join(:code.priv_dir(:quizaar), filename)
    case File.read(path) do
      {:ok, content} ->
        # Trim any extra whitespace
        {:ok, String.trim(content)}

      {:error, reason} ->

        {:error, reason}
    end
  end

  @doc """
  Generates questions based on the provided parameters.
  ## Parameters

    - `number`: The number of questions to generate.
    - `topic`: The topic of the questions.
    - `context`: A description for the questions (default: "none").
    - `difficulty`: The difficulty level of the questions (default: "normal").
  ## Returns
    - A tuple containing `:ok` and the generated questions in JSON format.
    - An error tuple if the request fails.
  ## Examples

      iex> generate_questions(5, "math", "none", "normal")
      {:ok, %{"questionsAnswers" => [%{"question" => "What is 2 + 2?", "answer" => "4"}]}}
      iex> generate_questions(3, "science", "none", "easy")
      {:ok, %{"questionsAnswers" => [%{"question" => "What is H2O?", "answer" => "Water"}]}}
  """
  def generate_questions(number, topic, context \\ "none", difficulty \\ "normal") do
    do_generate_questions(number, topic, context, difficulty, 0, 5)
  end

  defp do_generate_questions(number, topic, context, difficulty, attempt, max_attempts)
       when attempt < max_attempts do
    {:ok, prompt} = read_prompt("Prompt1.txt")

    updated_prompt =
      String.replace(prompt, ~r/%{number_of_questions}/, Integer.to_string(number))
      |> String.replace(~r/%{topic}/, topic)
      |> String.replace(~r/%{context}/, context)
      |> String.replace(~r/%{difficulty}/, difficulty)

    case query_llm(updated_prompt) do
      {:ok, res} ->
        case res["choices"] do
          [%{"message" => %{"content" => content}} | _] ->

            case Jason.decode(content) do
              {:ok, json} ->
                {:ok, json}

              _ ->
                do_generate_questions(
                  number,
                  topic,
                  context,
                  difficulty,
                  attempt + 1,
                  max_attempts
                )
            end

          _ ->
            do_generate_questions(number, topic, context, difficulty, attempt + 1, max_attempts)
        end


      {:error, reason} ->

        do_generate_questions(number, topic, context, difficulty, attempt + 1, max_attempts)
    end
  end

  defp do_generate_questions(_number, _topic, _context, _difficulty, _attempt, max_attempts) do
    {:error, "Failed to get valid JSON after #{max_attempts} attempts"}
  end

  @doc """
  Creates a list of questions based on the provided parameters.

  ## Parameters

    - `quiz_id`: The ID of the quiz to which the questions will be associated.
    - `config`: A map containing the configuration for generating questions. It can include:
      - `number`: The number of questions to generate (default: 5).
      - `topic`: The topic of the questions (default: "math").
      - `description`: A description for the questions (default: "none").
      - `difficulty`: The difficulty level of the questions (default: "normal").

  ## Returns

    - A list of question structs or maps, each representing a generated question.

  ## Examples

      iex> create_questions(1, %{number: 5, topic: "math", description: "none", difficulty: "normal"})
      [%Question{...}, %Question{...}, %Question{...}]

  """
  def create_questions(
        quiz_id,
        config \\ %{
          "number" => 5,
          "topic" => "math",
          "description" => "none",
          "difficulty" => "normal"
        },
        generator \\ &__MODULE__.generate_questions/4
      ) do
    config =
      for {k, v} <- config, into: %{} do
        {if(is_atom(k), do: k, else: String.to_atom(k)), v}
      end

    %{
      number: number,
      topic: topic,
      description: description,
      difficulty: difficulty
    } = config

    case generator.(number, topic, description, difficulty) do
      {:ok, questions} ->
        case get_quiz!(quiz_id) do
          nil ->
            {:error, "Quiz not found"}

          _ ->
            questions =
              questions["questionsAnswers"]
              |> Enum.map(fn attrs ->
                attrs = Map.put_new(attrs, "quiz_id", quiz_id)

                %Question{}
                |> Question.changeset(attrs)
                |> Repo.insert()
              end)

            {:ok, questions}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a question.

  ## Examples

      iex> update_question(question, %{field: new_value})
      {:ok, %Question{}}

      iex> update_question(question, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a question.

  ## Examples

      iex> delete_question(question)
      {:ok, %Question{}}

      iex> delete_question(question)
      {:error, %Ecto.Changeset{}}

  """
  def delete_question(%Question{} = question) do
    Repo.delete(question)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking question changes.

  ## Examples

      iex> change_question(question)
      %Ecto.Changeset{data: %Question{}}

  """
  def change_question(%Question{} = question, attrs \\ %{}) do
    Question.changeset(question, attrs)
  end

  def handle_question(%Quiz{} = quiz, %Question{} = question, time_limit) do
    Multi.new()
    |> Multi.update(
      :quiz,
      Quiz.changeset(quiz, %{
        current_question_id: question.id,
        question_started_at: DateTime.utc_now(),
        question_time_limit: time_limit
      })
    )
    |> Multi.update(:question, Question.changeset(question, %{used: true}))
    |> Repo.transaction()
  end

  def serve_question(%Quiz{} = quiz, time_limit \\ 60) do
    question = Repo.one(from q in Question, where: q.quiz_id == ^quiz.id and not q.used, limit: 1)

    if question do
      case handle_question(quiz, question, time_limit) do
        {:ok, res} ->
          # Successfully updated the quiz and question
          {:ok, res.question, res.quiz}

        {:error, _} ->
          # Handle error case
          {:error, "Failed to update quiz or question"}
      end
    else
      {:error, :end, "No available questions"}
    end
  end

  alias Quizaar.Quizzes.Answer

  @doc """
  Returns the list of answers.

  ## Examples

      iex> list_answers()
      [%Answer{}, ...]

  """
  def list_answers do
    Repo.all(Answer)
  end

  @doc """
  Gets a single answer.

  Raises `Ecto.NoResultsError` if the Answer does not exist.

  ## Examples

      iex> get_answer!(123)
      %Answer{}

      iex> get_answer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_answer!(id), do: Repo.get!(Answer, id)

  @doc """
  Creates a answer.

  ## Examples

      iex> create_answer(%{field: value})
      {:ok, %Answer{}}

      iex> create_answer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_answer(attrs \\ %{}) do
    %Answer{}
    |> Answer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a answer.

  ## Examples

      iex> update_answer(answer, %{field: new_value})
      {:ok, %Answer{}}

      iex> update_answer(answer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_answer(%Answer{} = answer, attrs) do
    answer
    |> Answer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a answer.

  ## Examples

      iex> delete_answer(answer)
      {:ok, %Answer{}}

      iex> delete_answer(answer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_answer(%Answer{} = answer) do
    Repo.delete(answer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking answer changes.

  ## Examples

      iex> change_answer(answer)
      %Ecto.Changeset{data: %Answer{}}

  """
  def change_answer(%Answer{} = answer, attrs \\ %{}) do
    Answer.changeset(answer, attrs)
  end

  alias Quizaar.Quizzes.Result

  @doc """
  Returns the list of results.

  ## Examples

      iex> list_results()
      [%Result{}, ...]

  """
  def list_results do
    Repo.all(Result)
  end

  @doc """
  Gets a single result.

  Raises `Ecto.NoResultsError` if the Result does not exist.

  ## Examples

      iex> get_result!(123)
      %Result{}

      iex> get_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_result!(id), do: Repo.get!(Result, id)

  @doc """
  Creates a result.

  ## Examples

      iex> create_result(%{field: value})
      {:ok, %Result{}}

      iex> create_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_result(attrs \\ %{}) do
    %Result{}
    |> Result.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a result.

  ## Examples

      iex> update_result(result, %{field: new_value})
      {:ok, %Result{}}

      iex> update_result(result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_result(%Result{} = result, attrs) do
    result
    |> Result.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a result.

  ## Examples

      iex> delete_result(result)
      {:ok, %Result{}}

      iex> delete_result(result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_result(%Result{} = result) do
    Repo.delete(result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking result changes.

  ## Examples

      iex> change_result(result)
      %Ecto.Changeset{data: %Result{}}

  """
  def change_result(%Result{} = result, attrs \\ %{}) do
    Result.changeset(result, attrs)
  end

  def check_if_answered(player_id, question_id) do
    query =
      from a in Answer,
        where: a.player_id == ^player_id and a.question_id == ^question_id,
        select: count(a.id)

    case Repo.one(query) do
      0 -> false
      _ -> true
    end
  end

  defp calculate_score(question_started_at, answer_time, allowed_time) do
    time_taken = DateTime.diff(answer_time, question_started_at)
    base_score = 200

    min_score = 50

    time_taken = min(time_taken, allowed_time)

    score =
      base_score - round((base_score - min_score) * (time_taken / allowed_time))

    max(score, min_score)
  end

  defp normalize_answer(answer) do
    answer
    |> String.downcase()
    |> String.replace(~r/\s+/, "")
  end

  defp corrected_by_llm(question, user_answer) do
    {:ok, prompt} = read_prompt("Prompt2.txt")

    updated_prompt =
      String.replace(prompt, ~r/%{question}/, question)
      |> String.replace(~r/%{answer}/, user_answer)

    {:ok, res} = query_llm(updated_prompt)

    case res["choices"] do
      [%{"message" => %{"content" => content}} | _] ->
        JSON.decode(content)

      _ ->
        {:error, "Unexpected response format"}
    end
  end

  defp check_if_correct(%Question{} = question, user_answer) do
    cond do
      # Exact match (normalized)
      normalize_answer(user_answer) == normalize_answer(question.answer) ->
        true

      # If options exist and answer is not correct, it's simply wrong
      not Enum.empty?(question.options) ->
        false

      # Otherwise, fallback to LLM correction
      true ->
        case corrected_by_llm(question.text, user_answer) do
          {:ok, res} ->
            correct_struct = res["corrected_answer"]
            correct_struct["correct"]

          {:error, _} ->
            false
        end
    end
  end

  @doc """
  Verifies the user's choice for a question and updates the answer and result accordingly.

  ## Parameters

    - `question`: The question being answered.
    - `quiz`: The quiz context.
    - `player_id`: The ID of the player answering the question.
    - `user_answer`: The answer provided by the user.

  ## Returns

    - A tuple with the result of the transaction, including the inserted answer and updated result.

  ## Examples

      iex> answer_and_score(question, quiz, player_id, "User's answer")
      {:ok, %Answer{}, %Result{}}
  """
  def answer_and_score(%Question{} = question, %Quiz{} = quiz, player_id, user_answer) do
    a_attrs = %{
      text: user_answer,
      question_id: question.id,
      player_id: player_id
    }

    is_correct = check_if_correct(question, user_answer)

    # Calculate score only if correct
    score =
      if is_correct do
        calculate_score(
          quiz.question_started_at,
          DateTime.utc_now(),
          quiz.question_time_limit
        )
      else
        0
      end

    Multi.new()
    |> Multi.insert(
      :answer,
      Answer.changeset(%Answer{}, Map.put(a_attrs, :is_correct, is_correct))
    )
    |> Multi.insert(
      :result,
      Result.changeset(
        %Result{},
        %{score: score, player_id: player_id}
      ),
      on_conflict: [inc: [score: score]],
      conflict_target: [:player_id]
    )
    |> Repo.transaction()
  end

  def fix_answer_scoring(%Quiz{} = quiz, answer) do
    import Ecto.Query, only: [from: 2]
    alias Quizaar.Repo
    alias Quizaar.Quizzes.Result
    alias Quizaar.Quizzes.Answer

    answer_id =
      cond do
        is_map(answer) and Map.has_key?(answer, "id") -> answer["id"]
        is_struct(answer) and Map.has_key?(answer, :id) -> answer.id
        true -> raise ArgumentError, "answer must have an id"
      end

    answer = Repo.get!(Answer, answer_id)

    score =
      calculate_score(
        quiz.question_started_at,
        answer.inserted_at,
        quiz.question_time_limit
      )

    score_delta = if answer.is_correct, do: -score, else: score

    Multi.new()
    |> Multi.update(
      :answer,
      Answer.changeset(answer, %{is_correct: !answer.is_correct})
    )
    |> Multi.update_all(
      :result,
      from(r in Result, where: r.player_id == ^answer.player_id),
      inc: [score: score_delta]
    )
    |> Repo.transaction()
  end

  def get_all_answers_to_current(question_id) do
    import Ecto.Query, only: [from: 2]
    alias Quizaar.Repo
    alias Quizaar.Quizzes.Answer
    alias Quizaar.Players.Player

    from(a in Answer,
      join: p in Player,
      on: a.player_id == p.id,
      where: a.question_id == ^question_id,
      preload: [player: p]
    )
    |> Repo.all()
  end

  def get_player_score(player_id) do
    import Ecto.Query, only: [from: 2]
    alias Quizaar.Repo
    alias Quizaar.Quizzes.Result

    from(r in Result,
      where: r.player_id == ^player_id,
      select: r.score
    )
    |> Repo.one()
  end

  def get_player_score_with_neighbours(player_id, quiz_id) do
    import Ecto.Query, only: [from: 2]
    alias Quizaar.Repo
    alias Quizaar.Quizzes.Result
    alias Quizaar.Players.Player

    # Get all players for this quiz and their scores, sorted descending
    results =
      from(p in Player,
        where: p.quiz_id == ^quiz_id,
        join: r in Result,
        on: r.player_id == p.id,
        order_by: [desc: r.score],
        select: %{player_id: p.id, score: r.score, name: p.name}
      )
      |> Repo.all()

    idx = Enum.find_index(results, fn r -> r.player_id == player_id end)

    higher_player =
      if idx && idx > 0, do: Enum.at(results, idx - 1), else: %{name: nil, score: nil}

    lower_player =
      if idx && idx < length(results) - 1,
        do: Enum.at(results, idx + 1),
        else: %{name: nil, score: nil}

    player = Enum.at(results, idx)

    %{
      higher_player: higher_player,
      player: Map.put(player, :placement, idx + 1),
      lower_player: lower_player
    }
  end

  def list_quizzes_by_user(user_id) do
    import Ecto.Query, only: [from: 2]
    alias Quizaar.Repo
    alias Quizaar.Quizzes.Quiz

    from(q in Quiz,
      where: q.user_id == ^user_id,
      order_by: [desc: q.inserted_at],
      select: q
    )
    |> Repo.all()
  end
end
