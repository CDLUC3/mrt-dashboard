FactoryBot.define do
  factory :inv_node do
    number 9999
    media_type 'unknown'
    media_connectivity 'cloud'
    access_mode 'on-line'
    access_protocol 's3'
    node_form 'physical'
    node_protocol 'file'
    logical_volume 'nodes-mrt-mock|9999'
    external_provider 'nodeio'
    verify_on_read true
    verify_on_write true
    base_url 'http://store.merritt.example.edu:54321'

    created { Time.now }
  end
end