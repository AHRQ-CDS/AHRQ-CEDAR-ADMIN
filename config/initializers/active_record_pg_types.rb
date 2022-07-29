require "active_record/connection_adapters/postgresql_adapter"

module PGAddTypes
  def initialize_type_map(m = type_map)
    super
    m.register_type "tsquery", ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::SpecializedString.new(:tsquery)
    m.register_type(3615, ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::SpecializedString.new(:tsquery))
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:tsquery] = { name: "tsquery" }
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend PGAddTypes
