# Annotator

Originally custom-built to annotate letters as part of my Folger Fellowship, I realised it might be useful as a simple general annotator for data, for example for machine learning labelling. I like using Google sheets because it records every change made in its history, plus multiple people can work on the same document. You can also manually make changes to the data - the annotator doesn't care.

While a demo is available here, I advise building your own version by cloning this repository and opening with R-Studio.

It needs an input csv with two columns: a unique key for each row, and the text for the thing to be labelled. This can contain HTML.

You need your own Google sheets API key, which is free to obtain and use. Instructions on this below.

You'll also need to create a Google sheet on google drive, and point the application to it.

## Clone the repository and open in R-Studio

The first step is to get a copy of the annotator running on your local machine. You can, if you want, publish it to your own shinyapps.io account (or other Shiny server), but if you're the only one using it, running it on your own machine will be fine.

#### Download R-Studio

If you don't already have it, you need to download R and R-Studio to run this on your local machine or publish to your own Shiny server. There are very straightforward instructions to do this here: <https://rstudio-education.github.io/hopr/starting.html>

#### Clone the repository to your own machine and open in RStudio.

There are few ways to do this. The 'best' way is to connect your copy of R-studio to Git using the instructions here: <https://happygitwithr.com/>, then 'fork' this repository to your own account, and finally open it in R-Studio. If this all makes sense to you, you probably don't need my step-by-step instructions.

A second method is to 'clone' this repository to R-Studio. This is pretty straightforward.

First, click on the green 'code' button above, and click on the highlighted icon to copy the web address for this repository to your clipboard.

![](clone.png)

Next, open R-Studio. Click on File-\> New Project-\> Version Control-\>Git

![](git.png)

Paste the repository URL into the first text box, and click 'Create Project'. It should download all the code in this repository, including the application.

#### Run the application
