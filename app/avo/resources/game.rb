class Avo::Resources::Game < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :session_id, as: :text
    field :description, as: :textarea
    field :theme_image_url, as: :text
    field :score, as: :number
    field :feedback, as: :code
    field :generated_image, as: :file
  end


  def actions
    # Register your bulk delete action here
    action Avo::Actions::BulkDestroy
  end
end
