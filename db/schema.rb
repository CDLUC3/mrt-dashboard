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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  create_table "inv_audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_node_id", limit: 2, null: false
    t.integer "inv_object_id", null: false
    t.integer "inv_version_id", null: false
    t.integer "inv_file_id", null: false
    t.string "url", limit: 16383
    t.string "status", limit: 18, default: "unknown", null: false
    t.datetime "created", null: false
    t.datetime "verified"
    t.datetime "modified"
    t.bigint "failed_size", default: 0, null: false
    t.string "failed_digest_value"
    t.text "note"
    t.index ["inv_file_id"], name: "id_idx3"
    t.index ["inv_node_id", "inv_version_id", "inv_file_id"], name: "inv_node_id", unique: true
    t.index ["inv_node_id"], name: "id_idx"
    t.index ["inv_object_id"], name: "id_idx1"
    t.index ["inv_version_id"], name: "id_idx2"
    t.index ["status"], name: "status"
    t.index ["verified"], name: "verified"
  end

  create_table "inv_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id"
    t.string "ark", null: false
    t.string "name"
    t.string "mnemonic"
    t.string "read_privilege", limit: 10
    t.string "write_privilege", limit: 10
    t.string "download_privilege", limit: 10
    t.string "storage_tier", limit: 8
    t.string "harvest_privilege", limit: 6, default: "none", null: false
    t.index ["ark"], name: "ark_UNIQUE", unique: true
    t.index ["harvest_privilege"], name: "id_hp"
    t.index ["inv_object_id"], name: "id_idx"
  end

  create_table "inv_collections_inv_nodes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_collection_id", limit: 2, null: false
    t.integer "inv_node_id", limit: 2, null: false
    t.datetime "created", null: false
    t.index ["inv_collection_id", "inv_node_id"], name: "inv_collection_id", unique: true
    t.index ["inv_collection_id"], name: "id_idx"
    t.index ["inv_node_id"], name: "id_idx1"
  end

  create_table "inv_collections_inv_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_collection_id", limit: 2, null: false
    t.integer "inv_object_id", null: false
    t.index ["inv_collection_id"], name: "id_idx"
    t.index ["inv_object_id"], name: "id_idx1"
  end

  create_table "inv_dublinkernels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.integer "inv_version_id", null: false
    t.integer "seq_num", limit: 2, null: false
    t.string "element", null: false
    t.string "qualifier"
    t.text "value", limit: 16777215, null: false
    t.index ["inv_object_id"], name: "id_idx"
    t.index ["inv_version_id"], name: "id_idx1"
  end

  create_table "inv_embargoes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.datetime "embargo_end_date", null: false
    t.index ["embargo_end_date"], name: "embargo_end_date"
    t.index ["inv_object_id"], name: "inv_object_id_UNIQUE", unique: true
  end

  create_table "inv_files", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.integer "inv_version_id", null: false
    t.text "pathname", limit: 4294967295, null: false
    t.string "source", limit: 8, null: false
    t.string "role", limit: 8, null: false
    t.bigint "full_size", default: 0, null: false
    t.bigint "billable_size", default: 0, null: false
    t.string "mime_type"
    t.string "digest_type", limit: 8
    t.string "digest_value"
    t.datetime "created", null: false
    t.index ["created"], name: "created"
    t.index ["inv_object_id"], name: "id_idx1"
    t.index ["inv_version_id"], name: "id_idx"
    t.index ["mime_type"], name: "mime_type"
    t.index ["role"], name: "role"
    t.index ["source"], name: "source"
  end

  create_table "inv_ingests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.integer "inv_version_id", null: false
    t.string "filename", null: false
    t.string "ingest_type", limit: 26, null: false
    t.string "profile", null: false
    t.string "batch_id", null: false
    t.string "job_id", null: false
    t.string "user_agent"
    t.datetime "submitted", null: false
    t.string "storage_url"
    t.index ["batch_id"], name: "batch_id"
    t.index ["inv_object_id"], name: "id_idx"
    t.index ["inv_version_id"], name: "id_idx1"
    t.index ["profile"], name: "profile"
    t.index ["submitted"], name: "submitted"
    t.index ["user_agent"], name: "user_agent"
  end

  create_table "inv_localids", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "inv_object_ark", null: false
    t.string "inv_owner_ark", null: false
    t.string "local_id", null: false
    t.datetime "created", null: false
    t.index ["inv_object_ark"], name: "id_idoba"
    t.index ["inv_owner_ark", "local_id"], name: "loc_unique", unique: true
    t.index ["inv_owner_ark"], name: "id_idowa"
    t.index ["local_id"], name: "id_idloc"
  end

  create_table "inv_metadatas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.integer "inv_version_id", null: false
    t.string "filename"
    t.string "md_schema", limit: 14, null: false
    t.string "version"
    t.string "serialization", limit: 4
    t.text "value", limit: 16777215
    t.index ["inv_object_id"], name: "id_idx"
    t.index ["inv_version_id"], name: "id_idx1"
    t.index ["version"], name: "id_metax", length: 191
  end

  create_table "inv_nodes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "number", null: false
    t.string "media_type", limit: 13, null: false
    t.string "media_connectivity", limit: 7, null: false
    t.string "access_mode", limit: 9, null: false
    t.string "access_protocol", limit: 10, null: false
    t.string "node_form", limit: 8, default: "virtual", null: false
    t.string "node_protocol", limit: 4, default: "file", null: false
    t.string "logical_volume"
    t.string "external_provider"
    t.boolean "verify_on_read", null: false
    t.boolean "verify_on_write", null: false
    t.string "base_url", limit: 2045, null: false
    t.datetime "created", null: false
    t.string "description"
    t.integer "source_node", limit: 2
    t.integer "target_node", limit: 2
  end

  create_table "inv_nodes_inv_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_node_id", limit: 2, null: false
    t.integer "inv_object_id", null: false
    t.string "role", limit: 9, null: false
    t.datetime "created", null: false
    t.datetime "replicated"
    t.integer "version_number", limit: 2
    t.datetime "replic_start", null: true
    t.bigint "replic_size", null: true
    t.string "completion_status", null: true
    t.text "note", null: true
    t.index ["inv_node_id"], name: "id_idx"
    t.index ["inv_object_id", "inv_node_id"], name: "inv_object_id", unique: true
    t.index ["inv_object_id"], name: "id_idx1"
    t.index ["replicated"], name: "id_idx2"
  end

  create_table "inv_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_owner_id", limit: 2, null: false
    t.string "ark", null: false
    t.string "md5_3", limit: 3
    t.string "object_type", limit: 14, null: false
    t.string "role", limit: 11, null: false
    t.string "aggregate_role", limit: 27
    t.integer "version_number", limit: 2, null: false
    t.text "erc_who", limit: 16777215
    t.text "erc_what", limit: 16777215
    t.text "erc_when", limit: 16777215
    t.text "erc_where", limit: 16777215
    t.datetime "created", null: false
    t.datetime "modified"
    t.index ["ark"], name: "ark_UNIQUE", unique: true, length: 190
    t.index ["created"], name: "created"
    t.index ["inv_owner_id"], name: "id_idx"
    t.index ["modified"], name: "modified"
  end

  create_table "inv_owners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id"
    t.string "ark", null: false
    t.string "name"
    t.index ["ark"], name: "ark_UNIQUE", unique: true
  end

  create_table "inv_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "inv_object_id", null: false
    t.string "ark", null: false
    t.integer "number", limit: 2, null: false
    t.string "note", limit: 16383
    t.datetime "created", null: false
    t.index ["ark"], name: "ark"
    t.index ["created"], name: "created"
    t.index ["inv_object_id"], name: "id_idx"
  end

  create_table "sha_dublinkernels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "value", limit: 16777215, null: false
    t.index ["value"], name: "value", type: :fulltext
  end

end
