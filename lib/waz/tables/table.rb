module WAZ
  module Tables
    # This class represents a Table on Windows Azure Tables API. These are the methods implemented from Microsoft's API description 
    # available on MSDN at http://msdn.microsoft.com/en-us/library/dd179423.aspx
    #
    #	# list available tables
    #	WAZ::Tables::Table.list
    #
  	# # get a specific table
  	# my_table = WAZ::Tables::Table.find('my-table')
  	#    
    #	# delete table
    #	my_table.destroy!
    #
    #	# create a new table
    #	WAZ::Tables::Table.create('new-table')
    #
    class Table
      class << self
        # Finds a table by name. It will return nil if no table was found.
        def find(table_name)
          begin 
            WAZ::Tables::Table.new(service_instance.get_table(table_name))
          rescue WAZ::Tables::TableDoesNotExist
            return nil
          end
        end
                
        # Returns an array of the existing tables (WAZ::Tables::Table) on the current 
        # Windows Azure Storage account.
        def list()
          tables, next_table_name = [], nil
          begin
            table_list, next_table_name = service_instance.list_tables(next_table_name)
            table_list.each do |table|
              tables << WAZ::Tables::Table.new({ :name => table[:name], :url => table[:url] })
            end
          end while next_table_name != nil and !next_table_name.empty?
          tables
        end
        
        # Creates a table on the current account.
        def create(table_name)
          raise WAZ::Storage::InvalidParameterValue, {:name => "name", :values => ["lower letters, numbers or - (hypen), and must not start or end with - (hyphen)"]} unless WAZ::Storage::ValidationRules.valid_name?(table_name)
          service_instance.create_table(table_name)
          WAZ::Tables::Table.new(:name => table_name)
        end
        
        # This method is internally used by this class. It's the way we keep a single instance of the 
        # service that wraps the calls the Windows Azure Tables API. It's initialized with the values
        # from the default_connection on WAZ::Storage::Base initialized thru establish_connection!
        def service_instance
          options = WAZ::Storage::Base.default_connection.merge(:type_of_service => "table")
          (@service_instances ||= {})[:account_name] ||= Service.new(options)
        end       
      end

      attr_accessor :name, :url

      def initialize(options = {})
        raise WAZ::Storage::InvalidOption, :name unless options.keys.include?(:name)
        self.name = options[:name]
        self.url = options[:url]        
      end
      
      # Removes the table from the current account.
      def destroy!
        self.class.service_instance.delete_table(self.name)
      end
    end
  end
end