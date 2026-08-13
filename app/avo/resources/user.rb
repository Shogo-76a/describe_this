class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :email_address, as: :text
    field :name, as: :text
    field :sessions, as: :has_many
    field :created_at, as: :date_time, readonly: true
    field :updated_at, as: :date_time, readonly: true
  end
end
