# encoding: UTF-8
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

  create_table 'annita', id: false, force: :cascade do |t|
    t.integer 'xnum', limit: 4
  end

  create_table 'annita_tbl', id: false, force: :cascade do |t|
    t.integer  'id',                 limit: 2,    default: 0,          null: false
    t.integer  'number',             limit: 4,                         null: false
    t.string   'media_type',         limit: 13,                        null: false
    t.string   'media_connectivity', limit: 7,                         null: false
    t.string   'access_mode',        limit: 9,                         null: false
    t.string   'access_protocol',    limit: 10,                        null: false
    t.string   'node_form',          limit: 8,    default: 'physical', null: false
    t.string   'logical_volume',     limit: 255
    t.string   'external_provider',  limit: 255
    t.boolean  'verify_on_read',                                       null: false
    t.boolean  'verify_on_write',                                      null: false
    t.string   'base_url',           limit: 2045,                      null: false
    t.datetime 'created',                                              null: false
    t.integer  'source_node',        limit: 2
    t.integer  'target_node',        limit: 2
  end

  create_table 'inv_audits', force: :cascade do |t|
    t.integer  'inv_node_id',         limit: 2,                         null: false
    t.integer  'inv_object_id',       limit: 4,                         null: false
    t.integer  'inv_version_id',      limit: 4,                         null: false
    t.integer  'inv_file_id',         limit: 4,                         null: false
    t.string   'url',                 limit: 16383
    t.string   'status',              limit: 18,    default: 'unknown', null: false
    t.datetime 'created',                                               null: false
    t.datetime 'verified'
    t.datetime 'modified'
    t.integer  'failed_size',         limit: 8,     default: 0,         null: false
    t.string   'failed_digest_value', limit: 255
    t.text     'note',                limit: 65535
  end

  add_index 'inv_audits', ['inv_file_id'], name: 'id_idx3', using: :btree
  add_index 'inv_audits', ['inv_node_id', 'inv_version_id', 'inv_file_id'], name: 'inv_node_id', unique: true, using: :btree
  add_index 'inv_audits', ['inv_node_id'], name: 'id_idx', using: :btree
  add_index 'inv_audits', ['inv_object_id'], name: 'id_idx1', using: :btree
  add_index 'inv_audits', ['inv_version_id'], name: 'id_idx2', using: :btree
  add_index 'inv_audits', ['status'], name: 'status', using: :btree
  add_index 'inv_audits', ['verified'], name: 'verified', using: :btree

  create_table 'inv_collections', force: :cascade do |t|
    t.integer 'inv_object_id',      limit: 4
    t.string  'ark',                limit: 255,                  null: false
    t.string  'name',               limit: 255
    t.string  'mnemonic',           limit: 255
    t.string  'read_privilege',     limit: 10
    t.string  'write_privilege',    limit: 10
    t.string  'download_privilege', limit: 10
    t.string  'storage_tier',       limit: 8
    t.string  'harvest_privilege',  limit: 6,   default: 'none', null: false
  end

  add_index 'inv_collections', ['ark'], name: 'ark_UNIQUE', unique: true, using: :btree
  add_index 'inv_collections', ['harvest_privilege'], name: 'id_hp', using: :btree
  add_index 'inv_collections', ['inv_object_id'], name: 'id_idx', using: :btree

  create_table 'inv_collections_inv_nodes', force: :cascade do |t|
    t.integer  'inv_collection_id', limit: 2, null: false
    t.integer  'inv_node_id',       limit: 2, null: false
    t.datetime 'created',                     null: false
  end

  add_index 'inv_collections_inv_nodes', ['inv_collection_id', 'inv_node_id'], name: 'inv_collection_id', unique: true, using: :btree
  add_index 'inv_collections_inv_nodes', ['inv_collection_id'], name: 'id_idx', using: :btree
  add_index 'inv_collections_inv_nodes', ['inv_node_id'], name: 'id_idx1', using: :btree

  create_table 'inv_collections_inv_objects', force: :cascade do |t|
    t.integer 'inv_collection_id', limit: 2, null: false
    t.integer 'inv_object_id',     limit: 4, null: false
  end

  add_index 'inv_collections_inv_objects', ['inv_collection_id'], name: 'id_idx', using: :btree
  add_index 'inv_collections_inv_objects', ['inv_object_id'], name: 'id_idx1', using: :btree

  create_table 'inv_duas', force: :cascade do |t|
    t.integer 'inv_collection_id',      limit: 2
    t.integer 'inv_object_id',          limit: 4,     null: false
    t.string  'identifier',             limit: 255
    t.string  'title',                  limit: 255,   null: false
    t.string  'terms',                  limit: 16383, null: false
    t.text    'template',               limit: 65535
    t.string  'accept_obligation',      limit: 8,     null: false
    t.string  'name_obligation',        limit: 8,     null: false
    t.string  'affiliation_obligation', limit: 8,     null: false
    t.string  'email_obligation',       limit: 8,     null: false
    t.string  'applicability',          limit: 10,    null: false
    t.string  'persistence',            limit: 9,     null: false
    t.string  'notification',           limit: 255,   null: false
  end

  add_index 'inv_duas', ['identifier'], name: 'identifier', using: :btree
  add_index 'inv_duas', ['inv_collection_id'], name: 'id_idx', using: :btree
  add_index 'inv_duas', ['inv_object_id'], name: 'id_idx1', using: :btree

  create_table 'inv_dublinkernels', force: :cascade do |t|
    t.integer 'inv_object_id',  limit: 4,        null: false
    t.integer 'inv_version_id', limit: 4,        null: false
    t.integer 'seq_num',        limit: 2,        null: false
    t.string  'element',        limit: 255,      null: false
    t.string  'qualifier',      limit: 255
    t.text    'value',          limit: 16777215, null: false
  end

  add_index 'inv_dublinkernels', ['inv_object_id'], name: 'id_idx', using: :btree
  add_index 'inv_dublinkernels', ['inv_version_id'], name: 'id_idx1', using: :btree

  create_table 'inv_embargoes', force: :cascade do |t|
    t.integer  'inv_object_id',    limit: 4, null: false
    t.datetime 'embargo_end_date',           null: false
  end

  add_index 'inv_embargoes', ['embargo_end_date'], name: 'embargo_end_date', using: :btree
  add_index 'inv_embargoes', ['inv_object_id'], name: 'inv_object_id_UNIQUE', unique: true, using: :btree

  create_table 'inv_files', force: :cascade do |t|
    t.integer  'inv_object_id',  limit: 4,                      null: false
    t.integer  'inv_version_id', limit: 4,                      null: false
    t.text     'pathname',       limit: 4294967295,             null: false
    t.string   'source',         limit: 8,                      null: false
    t.string   'role',           limit: 8,                      null: false
    t.integer  'full_size',      limit: 8,          default: 0, null: false
    t.integer  'billable_size',  limit: 8,          default: 0, null: false
    t.string   'mime_type',      limit: 255
    t.string   'digest_type',    limit: 8
    t.string   'digest_value',   limit: 255
    t.datetime 'created',                                       null: false
  end

  add_index 'inv_files', ['created'], name: 'created', using: :btree
  add_index 'inv_files', ['inv_object_id'], name: 'id_idx1', using: :btree
  add_index 'inv_files', ['inv_version_id'], name: 'id_idx', using: :btree
  add_index 'inv_files', ['mime_type'], name: 'mime_type', using: :btree
  add_index 'inv_files', ['role'], name: 'role', using: :btree
  add_index 'inv_files', ['source'], name: 'source', using: :btree

  create_table 'inv_ingests', force: :cascade do |t|
    t.integer  'inv_object_id',  limit: 4,   null: false
    t.integer  'inv_version_id', limit: 4,   null: false
    t.string   'filename',       limit: 255, null: false
    t.string   'ingest_type',    limit: 26,  null: false
    t.string   'profile',        limit: 255, null: false
    t.string   'batch_id',       limit: 255, null: false
    t.string   'job_id',         limit: 255, null: false
    t.string   'user_agent',     limit: 255
    t.datetime 'submitted',                  null: false
    t.string   'storage_url',    limit: 255
  end

  add_index 'inv_ingests', ['batch_id'], name: 'batch_id', using: :btree
  add_index 'inv_ingests', ['inv_object_id'], name: 'id_idx', using: :btree
  add_index 'inv_ingests', ['inv_version_id'], name: 'id_idx1', using: :btree
  add_index 'inv_ingests', ['profile'], name: 'profile', using: :btree
  add_index 'inv_ingests', ['submitted'], name: 'submitted', using: :btree
  add_index 'inv_ingests', ['user_agent'], name: 'user_agent', using: :btree

  create_table 'inv_localids', force: :cascade do |t|
    t.string   'inv_object_ark', limit: 255, null: false
    t.string   'inv_owner_ark',  limit: 255, null: false
    t.string   'local_id',       limit: 255, null: false
    t.datetime 'created',                    null: false
  end

  add_index 'inv_localids', ['inv_object_ark'], name: 'id_idoba', using: :btree
  add_index 'inv_localids', ['inv_owner_ark', 'local_id'], name: 'loc_unique', unique: true, using: :btree
  add_index 'inv_localids', ['inv_owner_ark'], name: 'id_idowa', using: :btree
  add_index 'inv_localids', ['local_id'], name: 'id_idloc', using: :btree

  create_table 'inv_metadatas', force: :cascade do |t|
    t.integer 'inv_object_id',  limit: 4,        null: false
    t.integer 'inv_version_id', limit: 4,        null: false
    t.string  'filename',       limit: 255
    t.string  'md_schema',      limit: 14,       null: false
    t.string  'version',        limit: 255
    t.string  'serialization',  limit: 4
    t.text    'value',          limit: 16777215
  end

  add_index 'inv_metadatas', ['inv_object_id'], name: 'id_idx', using: :btree
  add_index 'inv_metadatas', ['inv_version_id'], name: 'id_idx1', using: :btree
  add_index 'inv_metadatas', ['version'], name: 'id_metax', length: { 'version'=>191 }, using: :btree

  create_table 'inv_nodes', force: :cascade do |t|
    t.integer  'number',             limit: 4,                        null: false
    t.string   'media_type',         limit: 13,                       null: false
    t.string   'media_connectivity', limit: 7,                        null: false
    t.string   'access_mode',        limit: 9,                        null: false
    t.string   'access_protocol',    limit: 10,                       null: false
    t.string   'node_form',          limit: 8,    default: 'virtual', null: false
    t.string   'node_protocol',      limit: 4,    default: 'file',    null: false
    t.string   'logical_volume',     limit: 255
    t.string   'external_provider',  limit: 255
    t.boolean  'verify_on_read',                                      null: false
    t.boolean  'verify_on_write',                                     null: false
    t.string   'base_url',           limit: 2045,                     null: false
    t.datetime 'created',                                             null: false
    t.string   'description',        limit: 255
    t.integer  'source_node',        limit: 2
    t.integer  'target_node',        limit: 2
  end

  create_table 'inv_nodes_inv_objects', force: :cascade do |t|
    t.integer  'inv_node_id',    limit: 2, null: false
    t.integer  'inv_object_id',  limit: 4, null: false
    t.string   'role',           limit: 9, null: false
    t.datetime 'created',                  null: false
    t.datetime 'replicated'
    t.integer  'version_number', limit: 2
  end

  add_index 'inv_nodes_inv_objects', ['inv_node_id'], name: 'id_idx', using: :btree
  add_index 'inv_nodes_inv_objects', ['inv_object_id', 'inv_node_id'], name: 'inv_object_id', unique: true, using: :btree
  add_index 'inv_nodes_inv_objects', ['inv_object_id'], name: 'id_idx1', using: :btree
  add_index 'inv_nodes_inv_objects', ['replicated'], name: 'id_idx2', using: :btree

  create_table 'inv_objects', force: :cascade do |t|
    t.integer  'inv_owner_id',   limit: 2,        null: false
    t.string   'ark',            limit: 255,      null: false
    t.string   'md5_3',          limit: 3
    t.string   'object_type',    limit: 14,       null: false
    t.string   'role',           limit: 11,       null: false
    t.string   'aggregate_role', limit: 27
    t.integer  'version_number', limit: 2,        null: false
    t.text     'erc_who',        limit: 16777215
    t.text     'erc_what',       limit: 16777215
    t.text     'erc_when',       limit: 16777215
    t.text     'erc_where',      limit: 16777215
    t.datetime 'created',                         null: false
    t.datetime 'modified'
  end

  add_index 'inv_objects', ['ark'], name: 'ark_UNIQUE', unique: true, length: { 'ark'=>190 }, using: :btree
  add_index 'inv_objects', ['created'], name: 'created', using: :btree
  add_index 'inv_objects', ['inv_owner_id'], name: 'id_idx', using: :btree
  add_index 'inv_objects', ['modified'], name: 'modified', using: :btree

  create_table 'inv_owners', force: :cascade do |t|
    t.integer 'inv_object_id', limit: 4
    t.string  'ark',           limit: 255, null: false
    t.string  'name',          limit: 255
  end

  add_index 'inv_owners', ['ark'], name: 'ark_UNIQUE', unique: true, using: :btree

  create_table 'inv_versions', force: :cascade do |t|
    t.integer  'inv_object_id', limit: 4,     null: false
    t.string   'ark',           limit: 255,   null: false
    t.integer  'number',        limit: 2,     null: false
    t.string   'note',          limit: 16383
    t.datetime 'created',                     null: false
  end

  add_index 'inv_versions', ['ark'], name: 'ark', using: :btree
  add_index 'inv_versions', ['created'], name: 'created', using: :btree
  add_index 'inv_versions', ['inv_object_id'], name: 'id_idx', using: :btree

  create_table 'sha_dublinkernels', force: :cascade do |t|
    t.text 'value', limit: 16777215, null: false
  end

  add_index 'sha_dublinkernels', ['value'], name: 'value', type: :fulltext

end
