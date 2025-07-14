defmodule Quizaar.QuizzesTest do
   use ExUnit.Case, async: true
  use Quizaar.Support.DataCase
    alias Quizaar.Repo
    alias Quizaar.Quizzes

     setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Quizaar.Repo)
  end
  describe "create_quiz/1" do


    test "creates a quiz with valid attributes" do
     valid_attrs =  Factory.string_params_with_assocs(:quiz)

      assert {:ok, %Quizaar.Quizzes.Quiz{} = quiz} = Quizzes.create_quiz(valid_attrs)

      added_quiz = Repo.get(Quizaar.Quizzes.Quiz, quiz.id)
      assert added_quiz == quiz, "Quiz from DB should match the created quiz"
      assert added_quiz.join_code != nil, "Join code should not be nil"
      for {param_field, expected} <- valid_attrs do
        schema_field = String.to_existing_atom(param_field)
        actual = Map.get(quiz, schema_field)

        assert actual == expected,
               "Value did not match for field: #{param_field} \n expected: #{expected}, \n actual: #{actual}"
      end

    end

    test "returns error changeset with invalid attributes" do
      invalid_attrs = %{title: nil, description: nil}

      assert {:error, changeset} = Quizzes.create_quiz(invalid_attrs)
      assert changeset.valid? == false
    end
  end


  describe "create_questions/1" do


  test "creates questions with a mocked generator" do
    quiz = Factory.insert(:quiz)
    quiz_id = quiz.id

    config = %{
      "number" => 2,
      "topic" => "math",
      "description" => "simple math",
      "difficulty" => "easy"
    }

    # Mocked generator returns predictable questions
    mock_generator = fn _number, _topic, _desc, _diff ->
      {:ok,
        %{
          "questionsAnswers" => [
            %{"text" => "What is 2+2?", "answer" => "4", "options" => ["4", "3", "2"]},
            %{"text" => "What is 3+3?", "answer" => "6", "options" => ["6", "5", "4"]}
          ]
        }
      }
    end



    assert {:ok, questions} = Quizaar.Quizzes.create_questions(quiz_id, config, mock_generator)


    assert length(questions) == 2
    for {:ok, question} <- questions do
      assert question.quiz_id == quiz_id
    end
  end

  test "handles generator failure" do
    quiz = Factory.insert(:quiz)
    quiz_id = quiz.id

    config = %{
      "number" => 2,
      "topic" => "math",
      "description" => "simple math",
      "difficulty" => "easy"
    }

    # Mocked generator returns an error
    mock_generator = fn _, _, _, _ -> {:error, "Unexpected response format"} end

    assert {:error, _reason} = Quizaar.Quizzes.create_questions(quiz_id, config, mock_generator)
  end
end

describe "create_question/1 w/o API" do
  test "creates a question with valid attributes" do
    valid_attrs = Factory.string_params_with_assocs(:question)
    assert {:ok, %Quizaar.Quizzes.Question{} = question} = Quizzes.create_question(valid_attrs)
    added_question = Repo.get(Quizaar.Quizzes.Question, question.id)

    assert added_question == question, "Question from DB should match the created question"
    for {param_field, expected} <- valid_attrs do
      schema_field = String.to_existing_atom(param_field)
      actual = Map.get(question, schema_field)

      assert actual == expected,
             "Value did not match for field: #{param_field} \n expected: #{expected}, \n actual: #{actual}"
    end
     end
    test "returns error changeset with invalid attributes" do
          invalid_attrs = %{text: nil, answer: nil, options: nil}
          assert {:error, changeset} = Quizzes.create_question(invalid_attrs)
          assert changeset.valid? == false

        end
    end
    describe "update_question" do
      test "updates a question with valid attributes" do
        question = Factory.insert(:question)
        update_attrs = %{text: "Updated Question", answer: "Updated Answer", options: ["Option1", "Option2"]}

        assert {:ok, %Quizaar.Quizzes.Question{} = updated_question} =
          Quizzes.update_question(question, update_attrs)
        added_question = Repo.get(Quizaar.Quizzes.Question, updated_question.id)
        assert added_question.text == "Updated Question"
        assert added_question.answer == "Updated Answer"
        assert added_question.options == ["Option1", "Option2"]
      end

      test "returns error changeset with invalid attributes" do
        question = Factory.insert(:question)
        invalid_attrs = %{text: nil, answer: nil, options: nil}

        assert {:error, changeset} = Quizzes.update_question(question, invalid_attrs)
        assert changeset.valid? == false
      end
    end


    describe "serve_question/2" do
      test "marks question as used and returns updated question" do

        quiz = Factory.insert(:quiz)
        Factory.insert(:question, quiz: quiz, quiz_id: quiz.id, used: false)

        assert {:ok,  updated_question, quiz} = Quizzes.serve_question(quiz, 120)
       db_question =Repo.get(Quizaar.Quizzes.Question, updated_question.id)
       db_quiz = Repo.get(Quizaar.Quizzes.Quiz, quiz.id)
        assert db_question.used == true
        assert db_question.quiz_id == quiz.id

        assert db_quiz.question_time_limit == 120
        assert quiz.current_question_id == db_question.id

      end


    end

    describe "answer_and_score/4" do
      test "returns scores answer positively if answer is correct" do
         quiz = Factory.insert(:quiz)
        Factory.insert(:question, quiz: quiz, quiz_id: quiz.id, used: false, answer: "Correct Answer")
         assert {:ok,  updated_question, quiz} = Quizzes.serve_question(quiz, 120)
        player = Factory.insert(:player, quiz: quiz, quiz_id: quiz.id)
        user_answer = "Correct Answer"
        assert {:ok, %{result: result, answer: answer} } = Quizzes.answer_and_score(updated_question, quiz, player.id, user_answer)
        assert result.score > 0, "Score should be positive for correct answer"
        assert answer.is_correct == true, "Answer should be marked correct"
        assert user_answer == answer.text, "User answer should match the question answer"


      end
      test "returns scores answer negatively if answer is incorrect" do
        quiz = Factory.insert(:quiz)
        Factory.insert(:question, quiz: quiz, quiz_id: quiz.id, used: false, answer: "Correct Answer")
        assert {:ok,  updated_question, quiz} = Quizzes.serve_question(quiz, 120)
        player = Factory.insert(:player, quiz: quiz, quiz_id: quiz.id)
        user_answer = "Wrong Answer"
        assert {:ok, %{result: result, answer: answer} } = Quizzes.answer_and_score(updated_question, quiz, player.id, user_answer)

        assert result.score == 0, "Score should be negative for incorrect answer"
        assert answer.is_correct == false, "Answer should be marked incorrect"
        assert user_answer == answer.text, "User answer should match the question answer"

      end




    end

   describe "fix_answer_scoring/2" do
      test "updates answer and result with correct score" do
        quiz = Factory.insert(:quiz)
          Factory.insert(:question, quiz: quiz, quiz_id: quiz.id, used: false, answer: "Correct Answer")
          assert {:ok,  updated_question, quiz} = Quizzes.serve_question(quiz, 120)
          player = Factory.insert(:player, quiz: quiz, quiz_id: quiz.id)

            user_answer = "Correct Answer"
        assert {:ok, %{result: result, answer: answer} } = Quizzes.answer_and_score(updated_question, quiz, player.id, user_answer)
        assert result.score > 0

        assert {:ok, _} = Quizzes.fix_answer_scoring(quiz, answer)
        updated_result = Repo.get(Quizaar.Quizzes.Result, result.id)
        assert updated_result.score == 0

      end

    end



end
