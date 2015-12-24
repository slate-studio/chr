namespace :deploy do
  desc "Setup s3"
  task :setup_s3 => :environment do
    require 'aws-sdk'

    access_key_id     = ENV["access_key_id"]
    secret_access_key = ENV["secret_access_key"]
    host              = ENV["host"]
    app_name = host.gsub(".herokuapp.com", "")
    setup_s3(app_name, access_key_id, secret_access_key)

    ## Results
    puts @new_access_key_id
    puts @new_secret_access_key
    puts app_name
  end


  def setup_s3(app_name, access_key_id, secret_access_key)
    @new_access_key_id = ""
    @new_secret_access_key = ""
    Aws.config.update({
      region: 'us-west-2',
      credentials: Aws::Credentials.new(access_key_id, secret_access_key)
    })

    iam = Aws::IAM::Client.new
    s3  = Aws::S3::Client.new

    create_bucket(app_name, s3)
    add_cors_to_bucket(app_name, s3)
    create_amazon_user(app_name, iam)
    create_user_access_key(app_name, iam)
    add_user_policy(app_name, iam)

  end

  def create_bucket(bucket_name, s3)
    resp = s3.create_bucket({
      bucket: bucket_name,
      create_bucket_configuration: {
        location_constraint: "us-west-2",
      },
    })
  end

  def add_cors_to_bucket(bucket_name, s3)
    resp = s3.put_bucket_cors({
      bucket: bucket_name,
      cors_configuration: {
        cors_rules: [
          {
            allowed_headers: ["Authorization", "content"],
            allowed_methods: ["GET"],
            allowed_origins: ["*"],
            max_age_seconds: 3000,
          },
        ],
      },
    })
  end

  def create_amazon_user(user_name, iam)
    resp = iam.create_user({
      user_name: user_name,
    })
  end

  def create_user_access_key(user_name, iam)
    resp = iam.create_access_key({
      user_name: user_name,
    })
    @new_access_key_id     = resp.access_key.access_key_id
    @new_secret_access_key = resp.access_key.secret_access_key
  end

  def add_user_policy(app_name, iam)
    policy = {
                "Statement": [
                  {
                    "Action": [
                        "s3:ListAllMyBuckets"
                    ],
                    "Effect": "Allow",
                    "Resource": "arn:aws:s3:::*"
                  },
                  {
                    "Action": "s3:*",
                    "Effect": "Allow",
                    "Resource": "arn:aws:s3:::#{app_name}"
                  },
                  {
                    "Action": "s3:*",
                    "Effect": "Allow",
                    "Resource": "arn:aws:s3:::#{app_name}/*"
                  }
                ]
              }

    resp = iam.put_user_policy({
      user_name: app_name,
      policy_name: "#{app_name}_heroku",
      policy_document: policy.to_json,
    })
  end

end
