class GameUpdater
  def initialize(game, params)
    @game = game
    @params = params
  end

  # returns [success, errors, system_replies]
  def call
    if @game.update(@params)
      # enqueue job
      GenerateImageJob.perform_later(@game, "English")
      system_replies = [
        GameForm.new(feedback: "MVP版は2回目以降送信できません"),
        GameForm.new(feedback: "うーん...(想像中)")
      ]
      [ true, nil, system_replies ]
    else
      [ false, @game.errors, nil ]
    end
  end
end
