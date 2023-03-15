class CreateIpLookups < ActiveRecord::Migration[6.1]
  def change
    create_table :ip_lookups do |t|
      t.string :ip_address, index: true # Don't use native PostgreSQL IP type because we just need it for lookups
      t.jsonb :rdap_result, default: {}
      t.timestamps
    end
  end
end
