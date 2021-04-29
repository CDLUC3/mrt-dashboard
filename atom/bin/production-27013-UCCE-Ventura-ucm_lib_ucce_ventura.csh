setenv RAILS_ENV production

set date = `date +%Y%m%d`
set base = `get_ssm_value_by_name ui/atom-dir`

cd `get_ssm_value_by_name ui/dir`
NUXEO_URL=`get_ssm_value_by_name ui/nuxeo-base`

set feedURL	= "${NUXEO_URL}/ucldc_collection_27013.atom"
set userAgent	= "Atom processor/UC Merced Library UCCE Ventura County"
set profile	= "ucm_lib_ucce_ventura_content"
set groupID	= "ark:/13030/m5dr7rw3"
set updateFile	= "${base}/LastUpdate/lastFeedUpdate_27013-m5dr7rw3"
set log		= "${base}/logs/production-27013-${profile}_${date}.log"

# Log file
bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]" >& ${log} &

# No log file
# bundle exec rake "atom:update[${feedURL}, ${userAgent}, ${profile}, ${groupID}, ${updateFile}]"

exit
