#!/usr/bin/env Rscript

# This script plots BUSCOs across chromosomes where chromosomes are drawn to scale.
# By default, only chromosomes with >3 BUSCOs are plotted in order to filter out shrapnel and chromosomes are plotted in one column
# Can adjust script to adjust stringency of filtering e.g. include chr with just 1 BUSCO or to plot multiple columns.


library(tidyverse)
library(readr)
library(optparse)

# get args
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="location.tsv file", metavar="character"),
      make_option(c("-t", "--title"), type="character", default="output", 
              help="title of plot. Default is 'output'", metavar="character"),
        make_option(c("-c", "--fai"), type="character", 
                help="Contig lengths (fai file)", metavar="character")        
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

plot_title <- opt$title
locations <- read_tsv(opt$file)
contig_lengths <- read_tsv(opt$fai, col_names=FALSE)
colnames(contig_lengths) <- c('Seq', 'length', 'offset', 'linebases', 'linewidth')

# Format location data 
locations <- locations %>% filter(!grepl(':', query_chr))
locations <- merge(locations, contig_lengths, by.x="query_chr", by.y="Seq")
locations$Length <- locations$length *1000000 # 1 Mb
locations$start <- 0

order_list = unique(locations$status)
order_list = order_list [! order_list %in% "self"]
locations$status_f = factor(locations$status, levels=order_list)

num_contigs <- as.character(length(unique(locations$query_chr)))


# Adapted plot - plots each chr as a box of correct length
busco_paint <- function(spp_df, num_col, title, karyotype){
  sub_title <- paste("n contigs =", karyotype)
  the_plot <- ggplot(data = spp_df) +
    geom_rect(aes(xmin=start, xmax=length, ymax=0, ymin =12), colour="black", fill="white") + #colour="black" if don't want to apply red/black to boxes
    geom_rect(aes(xmin=position-1e3, xmax=position+1e3, ymax=0, ymin =12, fill=status_f)) + # was fill=status_f
    facet_wrap(query_chr ~., ncol=num_col, strip.position="right") + guides(scale="none") +
    xlab("Position (Mb)") +
    scale_x_continuous(labels=function(x)x/1e6, expand=c(0.005,1)) +
    scale_y_continuous(breaks=NULL) + labs(fill = "Reference conitg") +
    #theme(strip.text.y = element_blank(), # uncomment if want to remove facet i.e. contig labels
    theme(strip.text.y = element_text(angle = 0),
          strip.background = element_blank()) +
    theme(strip.text.x = element_text(margin = margin(0,0,0,0, "cm")), 
          panel.background = element_rect(fill = "white", colour = "white"), 
          panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
    theme(legend.position = "none") +
    theme(axis.line.x = element_line(color="black", size = 0.5)) +
    theme(legend.position="right") + ggtitle(label=title, subtitle= sub_title)  + 
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(plot.subtitle = element_text(hjust = 0.5)) +
    theme(plot.title=element_text(face="italic")) +
    guides(fill=guide_legend("Reference contig"), color = "none")
  return(the_plot)
}

p <- busco_paint(locations, 1, plot_title, num_contigs)

# Save results
ggsave(paste(as.character(opt$file), "_buscopainter.pdf", sep = ""), plot = p, width = 15, height = 30, units = "cm", device = "pdf")
ggsave(paste(as.character(opt$file), "_buscopainter.png", sep = ""), plot = p, width = 15, height = 30, units = "cm", device = "png")
