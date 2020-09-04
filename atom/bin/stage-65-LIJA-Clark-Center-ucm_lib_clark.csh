setenv RAILS_ENV stage

set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_65.atom"
set userAgent	= "Atom processor/UCM Library Clark Center for Japanese Art and Culture"
set profile	= "ucm_lib_clark_content"
set groupID	= "ark:/13030/m5n58jd1"
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_65-m5n58jd1"
set log		= "${base}/logs/stage-65-${profile}_${date}.log"

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

exit
