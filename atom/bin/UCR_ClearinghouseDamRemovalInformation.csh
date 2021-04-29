set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_26143.atom"
set userAgent	= "Atom processor/UC Riverside Library Nuxeo collection (Clearinghouse for Dam Removal Information)"
set profile	= "ucr_lib_nuxeo_content"
set collection	= "m5qg11t8"         # feed collection
set groupID	= "ark:/13030/${collection}"
# Was defined in atom.yml file, but now here
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_${collection}_ucldc_26143"
set log		= "${base}/logs/${profile}_ucldc_26143_${date}.log"

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

exit
