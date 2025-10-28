namespace :db do
  # Alto database creation tasks
  task :create_alto do
    Rails.application.load_tasks
    db_configs = ActiveRecord::Base.configurations.configurations
    alto_configs = db_configs.select { |config| config.name.include?('alto') }

    alto_configs.each do |config|
      next if config.env_name == 'test' && Rails.env != 'test'

      case config.adapter
      when 'sqlite3'
        # Create directory if it doesn't exist
        dir = File.dirname(config.database)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        # SQLite databases are created automatically when accessed
        puts "Created Alto database: #{config.database}"
      when 'postgresql'
        # For PostgreSQL, create database if it doesn't exist
        begin
          ActiveRecord::Base.establish_connection(
            adapter: config.adapter,
            host: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
            database: 'postgres'  # Connect to default postgres db
          )
          ActiveRecord::Base.connection.create_database(config.database)
          puts "Created Alto PostgreSQL database: #{config.database}"
        rescue ActiveRecord::DatabaseAlreadyExists
          puts "Alto database already exists: #{config.database}"
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      when 'mysql2'
        # For MySQL, create database if it doesn't exist
        begin
          ActiveRecord::Base.establish_connection(
            adapter: config.adapter,
            host: config.host,
            port: config.port,
            username: config.username,
            password: config.password
          )
          ActiveRecord::Base.connection.create_database(config.database)
          puts "Created Alto MySQL database: #{config.database}"
        rescue ActiveRecord::DatabaseAlreadyExists
          puts "Alto database already exists: #{config.database}"
        ensure
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end
  end

  # Alto database migration tasks
  namespace :migrate do
    task :alto do
      # Set up the connection for migrations
      ENV['RAILS_ENV'] ||= Rails.env

      # Load migrations from the Alto engine
      migrations_path = File.join(Alto::Engine.root, 'db', 'migrate')

      # Override the migration connection to use Alto's database
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths = [migrations_path]

      # Establish connection to Alto database
      alto_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'alto')&.first
      if alto_config
        ActiveRecord::Base.establish_connection(alto_config)
        ActiveRecord::MigrationContext.new(migrations_path, ActiveRecord::SchemaMigration).migrate
        puts "Migrated Alto database"
      else
        puts "No Alto database configuration found for #{Rails.env} environment"
      end
    end
  end

  # Alto database rollback tasks
  namespace :rollback do
    task :alto do
      ENV['RAILS_ENV'] ||= Rails.env

      migrations_path = File.join(Alto::Engine.root, 'db', 'migrate')
      alto_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'alto')&.first

      if alto_config
        ActiveRecord::Base.establish_connection(alto_config)
        ActiveRecord::MigrationContext.new(migrations_path, ActiveRecord::SchemaMigration).rollback
        puts "Rolled back Alto database"
      else
        puts "No Alto database configuration found for #{Rails.env} environment"
      end
    end
  end

  # Alto database reset tasks
  namespace :reset do
    task :alto do
      ENV['RAILS_ENV'] ||= Rails.env

      alto_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'alto')&.first

      if alto_config
        case alto_config.adapter
        when 'sqlite3'
          # For SQLite, just delete the file
          File.delete(alto_config.database) if File.exist?(alto_config.database)
          puts "Reset Alto SQLite database: #{alto_config.database}"
        when 'postgresql', 'mysql2'
          # For PostgreSQL/MySQL, drop and recreate
          ActiveRecord::Base.establish_connection(alto_config)
          ActiveRecord::Base.connection.drop_database(alto_config.database)
          ActiveRecord::Base.connection.create_database(alto_config.database)
          puts "Reset Alto database: #{alto_config.database}"
        end

        # Run migrations after reset
        Rake::Task['db:migrate:alto'].invoke
      else
        puts "No Alto database configuration found for #{Rails.env} environment"
      end
    end
  end

  # Shorthand task aliases
  task 'create:alto' => :create_alto
end