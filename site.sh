#!/bin/bash

# Output file for the sitemap
output_file="sitemap.xml"

# Function to generate URLs from sitemap.xml
generate_from_sitemap() {
  local url="$1"
  local sitemap_url="${url%/}/sitemap.xml"
  local urls=$(curl -s "$sitemap_url" | grep -oE '<loc[^>]*>[^<]+' | sed -e 's/<loc[^>]*>//')

  if [ -z "$urls" ]; then
    return 1
  fi

  for link in $urls; do
    # Escape special characters in the URL
    link=$(echo $link | sed 's/&/\&amp;/g')
    link=$(echo $link | sed 's/</\&lt;/g')
    link=$(echo $link | sed 's/>/\&gt;/g')

    # Generate sitemap entry for each URL
    echo "  <url>" >> $output_file
    echo "    <loc>$link</loc>" >> $output_file
    echo "  </url>" >> $output_file
  done

  return 0
}

# Function to crawl the website and generate URLs
generate_sitemap() {
  local url="$1"
  local urls=$(curl -s "$url" | grep -oE '<a[^>]+href="([^"]+)"' | sed -e 's/<a[^>]*href="//' -e 's/"//g')

  if [ -z "$urls" ]; then
    return 1
  fi

  for link in $urls; do
    # Ensure URLs are absolute and not relative
    if [[ $link == /* ]]; then
      link="$url$link"
    elif [[ $link != http* ]]; then
      link="$url/$link"
    fi

    # Escape special characters in the URL
    link=$(echo $link | sed 's/&/\&amp;/g')
    link=$(echo $link | sed 's/</\&lt;/g')
    link=$(echo $link | sed 's/>/\&gt;/g')

    # Generate sitemap entry for each URL
    echo "  <url>" >> $output_file
    echo "    <loc>$link</loc>" >> $output_file
    echo "  </url>" >> $output_file
  done

  return 0
}

# Prompt for the website URL
read -p "Enter the website URL (in the form of http): " website_url

# Check if the URL starts with http
if [[ $website_url != http* ]]; then
  echo "The URL should start with 'http'. Please try again."
  exit 1
fi

# Generate the sitemap header
echo '<?xml version="1.0" encoding="UTF-8"?>' > $output_file
echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> $output_file

# Try to generate URLs from sitemap.xml if available
generate_from_sitemap "$website_url"

# If sitemap.xml not found, fall back to crawling the website
if [ $? -ne 0 ]; then
  generate_sitemap "$website_url"
fi

# Add the sitemap footer
echo '</urlset>' >> $output_file

echo "Sitemap generated successfully. You can find it in $output_file."

