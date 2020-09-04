set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_26389.atom"
set userAgent	= "Atom processor/UC Merced Library Don Pedro Project"
set profile	= "ucm_lib_donpedro_content"
set collection	= "m5p60962"         # feed collection
set groupID	= "ark:/13030/${collection}"
# Was defined in atom.yml file, but now here
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_${collection}"
set log		= "${base}/logs/${profile}_${date}.log"

# default, but want to show calling sequence
@ delay = 60 * 5
@ batch_size = 10

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}, ${delay}, ${batch_size}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}, ${delay}, ${batch_size}]"


exit
