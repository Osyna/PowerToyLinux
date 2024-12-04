
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import JSONFormatter

# Must be a single transcript.
# transcript = YouTubeTranscriptApi.get_transcript('LbsD8A72gBo',  languages='fr')


transcript_list = YouTubeTranscriptApi.list_transcripts('LbsD8A72gBo')
transcript = transcript_list.find_generated_transcript(['en', 'fr'])

formatter = JSONFormatter()

# # .format_transcript(transcript) turns the transcript into a JSON string.
json_formatted = formatter.format_transcript(transcript.fetch())


# # Now we can write it out to a file.
with open('your_filename.json', 'w', encoding='utf-8') as json_file:
    json_file.write(json_formatted)

# # Now should have a new JSON file that you can easily read back into Python.