# frozen_string_literal: true

class CreateRoutingTableForBuildsMetadata < Gitlab::Database::Migration[2.0]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  TABLE_NAME = :ci_builds_metadata
  PARENT_TABLE_NAME = :p_ci_builds_metadata
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    revert_converting_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
