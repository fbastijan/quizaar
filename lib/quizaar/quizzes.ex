defmodule Quizaar.Quizzes do
  @moduledoc """
  The Quizzes context.
  """

  import Ecto.Query, warn: false
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
  def get_quiz_by_code!(join_code), do: Repo.get_by!(Quiz, join_code: join_code)





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
        {"Authorization", "Bearer #{System.get_env("GROQ_API_KEY")}"}, # Ensure the API key is set in your environment variables
        {"Accept", "application/json"}
      ]

      body = %{
        "model" => "meta-llama/llama-4-maverick-17b-128e-instruct",
        "response_format" => %{type: "json_object"},
          "temperature"=> 0.6,
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
          IO.inspect(response_body, label: "Raw Response Body")
          case Jason.decode(response_body) do
            {:ok, decoded_body} -> {:ok, decoded_body}
            {:error, decode_error} -> {:error, {:decode_error, decode_error}}
          end

        {:ok, %Finch.Response{status: status_code, body: error_body}} ->
          IO.inspect(error_body, label: "Error Response Body")
          {:error, {:http_error, status_code, error_body}}

        {:error, reason} ->
          IO.inspect(reason, label: "Request Error")
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
  def read_prompt(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        {:ok, String.trim(content)} # Trim any extra whitespace

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
  def generate_questions(number, topic, context\\ "none", difficulty\\ "normal") do
   {:ok, prompt} = read_prompt("lib/Prompt1.txt")

  updated_prompt = String.replace(prompt, ~r/%{number_of_questions}/, Integer.to_string(number))
                      |> String.replace(~r/%{topic}/, topic)
                      |> String.replace(~r/%{context}/, context)
                      |> String.replace(~r/%{difficulty}/, difficulty)
    {ok,res} =query_llm(updated_prompt)
    case res["choices"] do
      [%{"message" => %{"content" => content}} | _] ->
        Jason.decode(content)

      _ ->
        {:error, "Unexpected response format"}
    end

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
def create_questions(quiz_id, config \\ %{number: 5, topic: "math", description: "none", difficulty: "normal"}) do
  %{number: number, topic: topic, description: description, difficulty: difficulty} = config
  {:ok, questions} = generate_questions(number, topic, description, difficulty)
  case get_quiz!(quiz_id) do
    nil -> {:error, "Quiz not found"}
    _ ->
      questions = questions["questionsAnswers"]
                    |> Enum.map(fn attrs ->
                      attrs = Map.put_new(attrs, "quiz_id", quiz_id)
                      %Question{}
                      |> Question.changeset(attrs)
                      |> Repo.insert()
                    end)
      {:ok, questions}

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
end
