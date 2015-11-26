# Require this file to append Landlord rake tasks to ActiveRecord db rake tasks
# Enabled by default in the initializer

module Landlord
  class RakeTaskEnhancer
    
    TASKS = %w(db:migrate db:rollback db:migrate:up db:migrate:down db:migrate:redo db:seed)
    
    # This is a bit convoluted, but helps solve problems when using Landlord within an engine
    # See spec/integration/use_within_an_engine.rb
    
    class << self
      def enhance!
        TASKS.each do |name|
          task = Rake::Task[name]
          task.enhance do
            if should_enhance?
              enhance_task(task)
            end
          end
        end
      end
    
      def should_enhance?
        Landlord.db_migrate_tenants
      end
    
      def enhance_task(task)
        Rake::Task[task.name.sub(/db:/, 'landlord:')].invoke
      end
    end
    
  end
end

Landlord::RakeTaskEnhancer.enhance!
