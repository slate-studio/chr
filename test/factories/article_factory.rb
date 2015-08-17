FactoryGirl.define do
  factory :article do
    sequence(:title)          { Faker::Name.title}
    sequence(:description)    { Faker::Lorem.sentence }
    sequence(:body_html)      { Faker::Lorem.sentence }
    
    factory :article_with_sport_scope do
    after(:create) do |article|
      # if rand(2) == 1
        article.description = 'Sport News'
        article.save
      # end

    end
  end

  end
end
 