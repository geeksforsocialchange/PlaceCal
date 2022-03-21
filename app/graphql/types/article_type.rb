module Types
  class ArticleType < Types::BaseObject
    

    description 'A piece of news involving a partner'

    # field :id, ID, 
    #   null: false,
    #   description: 'ID of article'

    field :name, String, 
      description: 'The name of the article (alias for headline)',
      method: :title

    field :headline, String, 
      description: 'The title of the article',
      method: :title

    field :text, String, 
      description: 'The contents of the article (alias for articleBody)',
      method: :body
    
    field :article_body, String, 
      description: 'The contents of the article (in markdown format)',
      method: :body

    field :date_published, GraphQL::Types::ISO8601DateTime, 
      description: 'Date that the article was published on PlaceCal',
      method: :published_at

    field :date_created, GraphQL::Types::ISO8601DateTime, 
      description: 'The time that the article was created on PlaceCal',
      method:  :created_at

    field :date_updated, GraphQL::Types::ISO8601DateTime, 
      description: 'The time that the article was modified on PlaceCal',
      method: :updated_at

    field :provider, [PartnerType],      
      description: 'The partner this article is about',
      method: :partner


    # creativeWorkStatus: string, from is_draft
    # author: person, from user

  end
end


