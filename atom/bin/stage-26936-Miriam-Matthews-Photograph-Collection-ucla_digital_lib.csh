setenv RAILS_ENV stage

set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_26936.atom"
set userAgent	= "Atom processor/UCLA Digital Library Program"
set profile	= "ucla_digital_lib_content"
set groupID	= "ark:/13030/m5k40smm"
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_26936-m5k40smm"
set log		= "${base}/logs/stage-26936-${profile}_${date}.log"

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

exit
