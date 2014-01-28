NR-Bug-Analyzer
========

We built an analyzer tool, NR-Bug-Analyzer, to calculate a set of metrics. It 1) takes as input XML files, extracted from the filter/search results of our queries, 2) creates a set of new XML files per each bug report, 3) parses the values of needed fields in each bug report, 4) measures the metrics and 5) saves them all in a .csv file as an output. We used common fields in Bugzilla and Jira repositories (More details are available in the paper).

Also, The data retrieved from bug repositories does not contain any information on how the statuses and resolutions change over time for each bug report. To obtain the required historical data on status and resolution changes, our tool directly parses the HTML source of each NR bug report (More details are available in the paper).

The Data folder contains the detailed search queries used in our study (Queries.rtf), as well as the qualitative and quantitative results of each open source repositories (Firefox, Eclipse, Moodle, Wiki, Firefox-Andriod).

