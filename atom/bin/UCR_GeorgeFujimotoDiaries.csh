set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_81.atom"
set userAgent	= "Atom processor/ UC Riverside Library Nuxeo collection (George Fujimoto Diaries)"
set profile	= "ucr_lib_nuxeo_content"
set collection	= "m5qg11t8"         # feed collection
set groupID	= "ark:/13030/${collection}"
# Was defined in atom.yml file, but now here
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_${collection}_ucldc_81"
set log		= "${base}/logs/${profile}_ucldc_81_${date}.log"

# Very large number of TIF images per entry
@ delay = 60 * 40
@ batch_size = 1

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}, ${delay}, ${batch_size}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}, ${delay}, ${batch_size}]"

exit
