
import ../../libscrape


scraper "wp.videotube":
  extend "mcrawl", "--level=1 --dregex=mp4|m4v"