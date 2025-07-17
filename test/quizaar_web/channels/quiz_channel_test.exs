defmodule QuizaarWeb.QuizChannelTest do
  use QuizaarWeb.ChannelCase
  use Quizaar.Support.DataCase, async: true
  alias Quizaar.Accounts
  alias Quizaar.Accounts.Account
  alias Quizaar.Users
  alias Quizaar.Players
  alias QuizaarWeb.QuizChannel
  alias QuizaarWeb.UserSocket

  alias QuizaarWeb.Auth.Guardian

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Quizaar.Repo)
    :ok
  end

  describe "Joining channel" do
    test "join/3 with valid params as organizer" do
      params = Factory.string_params_for(:account)

      {:ok, %Account{} = account} = Accounts.create_account(params)

      {:ok, token, _claims} = Guardian.encode_and_sign(account)

      params = %{"full_name" => "test"}
      {:ok, user} = Users.create_user(account, params)

      quiz = Factory.insert(:quiz, join_code: "test-join-code", user_id: user.id, user: user)

      {:ok, _, socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{token: token})

      assert socket.assigns.account.id == account.id
      assert socket.assigns.account.user.id == user.id
      assert socket.assigns.role == "organizer"
      assert socket.assigns.quiz.id == quiz.id
      assert socket.assigns.join_code == quiz.join_code
    end

    test "join as registered user but not organizer" do
      params = Factory.string_params_for(:account)

      {:ok, %Account{} = account} = Accounts.create_account(params)

      {:ok, token, _claims} = Guardian.encode_and_sign(account)

      params = %{"full_name" => "test"}
      {:ok, user} = Users.create_user(account, params)

      quiz = Factory.insert(:quiz, join_code: "test-join-code")

      {:ok, _, socket} =
        socket(QuizaarWeb.UserSocket)
        |> subscribe_and_join(QuizaarWeb.QuizChannel, "quiz:#{quiz.join_code}", %{token: token})

      # checks if joined
      assert socket.assigns.role == "player"
      assert socket.assigns.account.id == account.id
      assert socket.assigns.account.user.id == user.id
      assert socket.assigns.quiz.id == quiz.id
      assert socket.assigns.join_code == quiz.join_code

      # checks if player was inserted to db
      player = Players.get_player_by_user_and_quiz(user.id, quiz.id)
      assert player != nil
      assert player.name == user.full_name
    end

    test "join as a guest" do
      quiz = Factory.insert(:quiz, join_code: "test-join-code")

      {:ok, _, socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{name: "anyone"})

      # checks if joined
      assert socket.assigns.role == "player"
      assert socket.assigns.session_id != nil
      assert "anyone" == socket.assigns.name
      assert socket.assigns.guest == true

      # checks if player was inserted to db
      player = Players.get_player_by_session_id(socket.assigns.session_id)
      assert player != nil
      assert player.name == socket.assigns.name
    end
  end

  describe "organizer actions" do
    setup do
      params = Factory.string_params_for(:account)

      {:ok, %Account{} = account} = Accounts.create_account(params)

      {:ok, token, _claims} = Guardian.encode_and_sign(account)

      params = %{"full_name" => "test"}
      {:ok, user} = Users.create_user(account, params)

      quiz =
        Factory.insert(:quiz,
          join_code: "handletest",
          user_id: user.id,
          user: user,
          question_started_at: DateTime.utc_now(),
          question_time_limit: 30
        )

      {:ok, _, socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{token: token})

      {:ok, _, player_socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{name: "anyone"})

      {:ok,
       socket: socket, quiz: quiz, user: user, account: account, player_socket: player_socket}
    end

    #  test "handle_in/3 generate_questions",  %{socket: socket}do

    #     # Simulate the push event to generate questions

    #   ref =  push(socket, "generate_questions", %{
    #       "number" => 5,
    #      "topic" => "Unit testing",
    #       "description" => "Testing the quiz generation",
    #       "difficulty"=> "medium"
    #     })

    #    assert_reply ref, :ok, %{"message" => "Questions generated successfully"}, 1000
    #     assert_push "questions_generated", %{questions: "questions"}, 1000

    #  end

    test "handle_in/3 generate_questions failed you are not org", %{player_socket: player_socket} do
      # Simulate the push event to generate questions
      ref =
        push(player_socket, "generate_questions", %{
          "number" => 5,
          "topic" => "Unit testing",
          "description" => "Testing the quiz generation",
          "difficulty" => "medium"
        })

      assert_reply ref, :error, %{message: "You are not authorized to generate questions"}, 1000
    end

    test "handle_in/3 get_players", %{socket: socket, quiz: quiz, player_socket: player_socket} do
      ref = push(socket, "get_players", %{})

      assert_reply ref, :ok, %{players: players}, 1000
      assert Enum.at(players, 0).id == player_socket.assigns.player.id
    end

    test "handle_in/3 serve_question", %{socket: socket, quiz: quiz} do
      question = Factory.insert(:question, quiz_id: quiz.id, quiz: quiz)
      ref = push(socket, "serve_question", %{})

      assert_reply ref, :ok, %{question: re_question}
      assert question.id == re_question.data.id

      assert_broadcast "question_served", %{question: question}, 1000
      assert question.data.used == true
    end

    test "handle_in/3 serve_question when no questions", %{socket: socket, quiz: quiz} do
      ref = push(socket, "serve_question", %{})

      assert_reply ref, :error, reason, 1000
      assert reason == "No available questions"
    end

    test "handle_in/3 serve_question when not organizer", %{player_socket: player_socket} do
      ref = push(player_socket, "serve_question", %{})

      assert_reply ref, :error, %{message: "You are not authorized to serve questions"}, 1000
    end

    test "handle_in/3 delete_player", %{player_socket: player_socket, socket: socket} do
      player_id = player_socket.assigns.player.id
      ref = push(socket, "delete_player", %{player_id: player_id})
      assert_reply ref, :ok, %{player: player}
      assert player.id == player_id
    end

    test "handle_in/3 no player to delete", %{player_socket: player_socket, socket: socket} do
      player_id = socket.assigns.account.id
      ref = push(socket, "delete_player", %{player_id: player_id})
      assert_reply ref, :error, %{message: "Player not found to delete"}
    end

    test "handle_in/3 delete_player when not organizer", %{player_socket: player_socket} do
      player_id = player_socket.assigns.player.id
      ref = push(player_socket, "delete_player", %{player_id: player_id})
      assert_reply ref, :error, %{message: "You are not authorized to delete players"}
    end

    test "handle_in/3 start_quiz", %{socket: socket, quiz: quiz, player_socket: player_socket} do
      Factory.insert(:question, quiz_id: quiz.id, quiz: quiz)
      ref_ready = push(player_socket, "ready_up", %{})
      assert_reply ref_ready, :ok, %{"message" => "You are ready"}
      ref = push(socket, "quiz_start", %{})
      assert_reply ref, :ok, %{question: _re_question}
      assert_broadcast "quiz_start", %{message: "Quiz is starting!"}
    end

    test "handle_in/3 start_quiz when not ready", %{socket: socket, quiz: quiz} do
      Factory.insert(:question, quiz_id: quiz.id, quiz: quiz)
      ref = push(socket, "quiz_start", %{})
      assert_reply ref, :error, %{message: "Not all players are ready"}, 1000
    end

    test "handle_in/3 start_quiz when not organizer", %{player_socket: player_socket} do
      ref = push(player_socket, "quiz_start", %{})
      assert_reply ref, :error, %{message: "You are not authorized to start the quiz"}, 1000
    end

    test "handle_in/3 fix answer", %{player_socket: player_socket, socket: socket, quiz: quiz} do
      question =
        Factory.insert(:question, quiz_id: quiz.id, quiz: quiz)
        |> Map.from_struct()

      push(player_socket, "ready_up", %{})
      ref = push(player_socket, "answer_question", %{question: question, answer: "any answer"})
      assert_reply ref, :ok, %{result: _, answer: answer}, 1000

      answer = Repo.get!(Quizaar.Quizzes.Answer, answer)
      ref = push(socket, "fix_answer", %{question_id: question.id, answer: answer})

      assert_reply ref, :ok, %{answer: fixed}, 1000
      assert_broadcast "answer_received", %{fixed: true}, 1000
      fixed = fixed.data
      assert fixed.id == answer.id
      assert fixed.is_correct != answer.is_correct
    end
  end

  describe "Player actions" do
    setup do
      params = Factory.string_params_for(:account)

      {:ok, %Account{} = account} = Accounts.create_account(params)

      {:ok, token, _claims} = Guardian.encode_and_sign(account)

      params = %{"full_name" => "test"}
      {:ok, user} = Users.create_user(account, params)

      quiz = Factory.insert(:quiz, join_code: "handletest", user_id: user.id, user: user)

      question =
        Factory.insert(:question, quiz_id: quiz.id, quiz: quiz)
        |> Map.from_struct()

      {:ok, _, socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{token: token})

      {:ok, _, player_socket} =
        socket(UserSocket)
        |> subscribe_and_join(QuizChannel, "quiz:#{quiz.join_code}", %{name: "anyone"})

      push(player_socket, "ready_up", %{})
      push(socket, "serve_question", %{})
      assert_push "question_served", %{question: question}, 1000

      {:ok,
       socket: socket,
       quiz: quiz,
       user: user,
       account: account,
       question: question.data,
       player_socket: player_socket}
    end

    test "handle_in/3 answer_question", %{player_socket: player_socket, question: question} do
      push(player_socket, "ready_up", %{})
      ref = push(player_socket, "answer_question", %{question: question, answer: "any answer"})

      assert_reply ref, :ok, %{result: _, answer: _}, 1000
    end

    test "handle_in/3 ready player", %{player_socket: player_socket, quiz: quiz} do
      session_id = player_socket.assigns.player.session_id
      ref = push(player_socket, "ready_up", %{})
      assert_reply ref, :ok, %{"message" => "You are ready"}
      assert_push "presence_update", presence

      pres = presence[session_id].metas
      assert Enum.at(pres, 0).ready == true
    end

    test "handle_in/3 ready player when not player", %{socket: socket} do
      ref = push(socket, "ready_up", %{})

      assert_reply ref, :error, %{message: "Only players can ready up"}
    end

    test "handle_in/3 unready", %{player_socket: player_socket} do
      session_id = player_socket.assigns.player.session_id
      ref = push(player_socket, "unready", %{})
      assert_reply ref, :ok, %{"message" => "You are no longer ready"}
      assert_push "presence_update", presence
    end
  end
end
