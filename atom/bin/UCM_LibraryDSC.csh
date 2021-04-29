set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_26144.atom"
set userAgent	= "Atom processor/UCM Library Digital Special Collecitions"
set profile	= "ucm_lib_dsc_content"
set collection	= "m5wm1bf0"         # feed collection
set groupID	= "ark:/13030/${collection}"
# Was defined in atom.yml file, but now here
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_${collection}"
set log		= "${base}/logs/${profile}_${date}.log"

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

exit
