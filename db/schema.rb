# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "inv_collections", :force => true do |t|
    t.integer "inv_object_id"
    t.string  "ark",                             :null => false
    t.string  "name"
    t.string  "mnemonic"
    t.string  "read_privilege",     :limit => 0
    t.string  "write_privilege",    :limit => 0
    t.string  "download_privilege", :limit => 0
    t.string  "storage_tier",       :limit => 0
  end

  add_index "inv_collections", ["ark"], :name => "ark_UNIQUE", :unique => true
  add_index "inv_collections", ["inv_object_id"], :name => "id_idx"

  create_table "inv_collections_inv_objects", :force => true do |t|
    t.integer "inv_collection_id", :limit => 2, :null => false
    t.integer "inv_object_id",                  :null => false
  end

  add_index "inv_collections_inv_objects", ["inv_collection_id"], :name => "id_idx"
  add_index "inv_collections_inv_objects", ["inv_object_id"], :name => "id_idx1"

  create_table "inv_duas", :force => true do |t|
    t.integer "inv_collection_id",      :limit => 2
    t.integer "inv_object_id",                           :null => false
    t.string  "identifier"
    t.string  "title",                                   :null => false
    t.string  "terms",                  :limit => 16383, :null => false
    t.text    "template"
    t.string  "accept_obligation",      :limit => 0,     :null => false
    t.string  "name_obligation",        :limit => 0,     :null => false
    t.string  "affiliation_obligation", :limit => 0,     :null => false
    t.string  "email_obligation",       :limit => 0,     :null => false
    t.string  "applicability",          :limit => 0,     :null => false
    t.string  "persistence",            :limit => 0,     :null => false
    t.string  "notification",                            :null => false
  end

  add_index "inv_duas", ["identifier"], :name => "identifier"
  add_index "inv_duas", ["inv_collection_id"], :name => "id_idx"
  add_index "inv_duas", ["inv_object_id"], :name => "id_idx1"

  create_table "inv_dublinkernels", :force => true do |t|
    t.integer "inv_object_id",                   :null => false
    t.integer "inv_version_id",                  :null => false
    t.integer "seq_num",        :limit => 2,     :null => false
    t.string  "element",                         :null => false
    t.string  "qualifier"
    t.string  "value",          :limit => 20000, :null => false
  end

  add_index "inv_dublinkernels", ["inv_object_id"], :name => "id_idx"
  add_index "inv_dublinkernels", ["inv_version_id"], :name => "id_idx1"

  create_table "inv_files", :force => true do |t|
    t.integer   "inv_object_id",                                  :null => false
    t.integer   "inv_version_id",                                 :null => false
    t.string    "pathname",       :limit => 16383,                :null => false
    t.string    "source",         :limit => 0,                    :null => false
    t.string    "role",           :limit => 0,                    :null => false
    t.integer   "full_size",      :limit => 8,     :default => 0, :null => false
    t.integer   "billable_size",  :limit => 8,     :default => 0, :null => false
    t.string    "mime_type"
    t.string    "digest_type",    :limit => 0
    t.string    "digest_value"
    t.timestamp "created",                                        :null => false
  end

  add_index "inv_files", ["created"], :name => "created"
  add_index "inv_files", ["inv_object_id"], :name => "id_idx1"
  add_index "inv_files", ["inv_version_id"], :name => "id_idx"
  add_index "inv_files", ["mime_type"], :name => "mime_type"
  add_index "inv_files", ["role"], :name => "role"
  add_index "inv_files", ["source"], :name => "source"

  create_table "inv_ingests", :force => true do |t|
    t.integer   "inv_object_id",               :null => false
    t.integer   "inv_version_id",              :null => false
    t.string    "filename",                    :null => false
    t.string    "type",           :limit => 0, :null => false
    t.string    "profile",                     :null => false
    t.string    "batch_id",                    :null => false
    t.string    "job_id",                      :null => false
    t.string    "user_agent"
    t.timestamp "submitted",                   :null => false
    t.string    "storage_url"
  end

  add_index "inv_ingests", ["batch_id"], :name => "batch_id"
  add_index "inv_ingests", ["inv_object_id"], :name => "id_idx"
  add_index "inv_ingests", ["inv_version_id"], :name => "id_idx1"
  add_index "inv_ingests", ["profile"], :name => "profile"
  add_index "inv_ingests", ["submitted"], :name => "submitted"
  add_index "inv_ingests", ["user_agent"], :name => "user_agent"

  create_table "inv_metadatas", :force => true do |t|
    t.integer "inv_object_id",               :null => false
    t.integer "inv_version_id",              :null => false
    t.string  "filename",                    :null => false
    t.string  "md_schema",      :limit => 0, :null => false
    t.string  "version"
    t.string  "serialization",  :limit => 0
    t.text    "value"
  end

  add_index "inv_metadatas", ["inv_object_id"], :name => "id_idx"
  add_index "inv_metadatas", ["inv_version_id"], :name => "id_idx1"

  create_table "inv_nodes", :force => true do |t|
    t.integer   "number",                             :null => false
    t.string    "media_type",         :limit => 0,    :null => false
    t.string    "media_connectivity", :limit => 0,    :null => false
    t.string    "access_mode",        :limit => 0,    :null => false
    t.string    "access_protocol",    :limit => 0,    :null => false
    t.string    "logical_volume"
    t.string    "external_provider"
    t.boolean   "verify_on_read",                     :null => false
    t.boolean   "verify_on_write",                    :null => false
    t.string    "base_url",           :limit => 2045, :null => false
    t.timestamp "created",                            :null => false
  end

  create_table "inv_nodes_inv_objects", :force => true do |t|
    t.integer   "inv_node_id",   :limit => 2, :null => false
    t.integer   "inv_object_id",              :null => false
    t.string    "role",          :limit => 0, :null => false
    t.timestamp "created",                    :null => false
  end

  add_index "inv_nodes_inv_objects", ["inv_node_id"], :name => "id_idx"
  add_index "inv_nodes_inv_objects", ["inv_object_id"], :name => "id_idx1"

  create_table "inv_objects", :force => true do |t|
    t.integer   "inv_owner_id",   :limit => 2,    :null => false
    t.string    "ark",                            :null => false
    t.string    "type",           :limit => 0,    :null => false
    t.string    "role",           :limit => 0,    :null => false
    t.string    "aggregate_role", :limit => 0
    t.integer   "version_number", :limit => 2,    :null => false
    t.string    "erc_who",        :limit => 5394
    t.string    "erc_what",       :limit => 5394
    t.string    "erc_when",       :limit => 5394
    t.string    "erc_where",      :limit => 5394
    t.timestamp "created",                        :null => false
    t.timestamp "modified"
  end

  add_index "inv_objects", ["ark"], :name => "ark_UNIQUE", :unique => true
  add_index "inv_objects", ["created"], :name => "created"
  add_index "inv_objects", ["inv_owner_id"], :name => "id_idx"
  add_index "inv_objects", ["modified"], :name => "modified"

  create_table "inv_owners", :force => true do |t|
    t.integer "inv_object_id"
    t.string  "ark",           :null => false
    t.string  "name"
  end

  add_index "inv_owners", ["ark"], :name => "ark_UNIQUE", :unique => true

  create_table "inv_versions", :force => true do |t|
    t.integer   "inv_object_id",                  :null => false
    t.string    "ark",                            :null => false
    t.integer   "number",        :limit => 2,     :null => false
    t.string    "note",          :limit => 16383
    t.timestamp "created",                        :null => false
  end

  add_index "inv_versions", ["ark"], :name => "ark"
  add_index "inv_versions", ["created"], :name => "created"
  add_index "inv_versions", ["inv_object_id"], :name => "id_idx"

  create_table "mrt_collections", :force => true do |t|
    t.string "ark", :limit => 254, :null => false
  end

  create_table "mrt_collections_mrt_objects", :force => true do |t|
    t.integer "mrt_object_id",     :null => false
    t.integer "mrt_collection_id", :null => false
  end

  add_index "mrt_collections_mrt_objects", ["mrt_collection_id"], :name => "collectionid_fk"
  add_index "mrt_collections_mrt_objects", ["mrt_object_id"], :name => "collection_objectid_fk"

  create_table "mrt_files", :force => true do |t|
    t.string    "bytestream",     :limit => 2048
    t.timestamp "created",                        :null => false
    t.string    "filename",       :limit => 254,  :null => false
    t.string    "media_type",     :limit => 254,  :null => false
    t.string    "sha1",           :limit => 254,  :null => false
    t.integer   "size",           :limit => 8,    :null => false
    t.integer   "mrt_version_id",                 :null => false
  end

  add_index "mrt_files", ["mrt_version_id"], :name => "versionid_fk"

  create_table "mrt_objects", :force => true do |t|
    t.string    "bytestream",        :limit => 254,  :null => false
    t.timestamp "created",                           :null => false
    t.string    "local_id",          :limit => 1024
    t.timestamp "last_add_version",                  :null => false
    t.integer   "num_actual_files",  :limit => 8,    :null => false
    t.string    "primary_id",        :limit => 254,  :null => false
    t.integer   "size",              :limit => 8,    :null => false
    t.string    "storage_url",       :limit => 254,  :null => false
    t.integer   "total_actual_size", :limit => 8,    :null => false
  end

  add_index "mrt_objects", ["id", "last_add_version"], :name => "mrt_objects_id_last_add_version"
  add_index "mrt_objects", ["last_add_version"], :name => "mrt_objects_last_add_version"

  create_table "mrt_version_metadata", :force => true do |t|
    t.integer "mrt_version_id",                 :null => false
    t.string  "name",           :limit => 254,  :null => false
    t.string  "value",          :limit => 2048, :null => false
  end

  add_index "mrt_version_metadata", ["mrt_version_id"], :name => "versionid_md_fk"

  create_table "mrt_versions", :force => true do |t|
    t.string    "bytestream",        :limit => 254,  :null => false
    t.timestamp "created",                           :null => false
    t.string    "local_id",          :limit => 1024
    t.integer   "num_actual_files",  :limit => 8,    :null => false
    t.integer   "mrt_object_id",                     :null => false
    t.string    "storageurl",        :limit => 254,  :null => false
    t.integer   "total_actual_size", :limit => 8,    :null => false
    t.integer   "total_size",        :limit => 8,    :null => false
    t.integer   "version_number",                    :null => false
  end

  add_index "mrt_versions", ["mrt_object_id"], :name => "objectid_fk"

end
