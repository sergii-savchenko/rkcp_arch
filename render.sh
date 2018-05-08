rm -rf ./assets || 0
cp -r ./content/assets ./assets
cat content/*.md > README.md
markdown-cli-renderer README.md README.html
