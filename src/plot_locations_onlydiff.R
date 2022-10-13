#!/usr/bin/env Rscript
library(tidyverse)
library(optparse)
 
# get args
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="location.tsv file", metavar="character")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


locations <- read_tsv(opt$file)

# Reorder factor to plot Merians in ascending order
locations <- locations %>% filter(!grepl(':', query_chr))
locations <- locations %>% filter(!grepl(':', status))

order_list = unique(locations$status)
order_list = order_list [! order_list %in% "self"]
locations$status_f = factor(locations$status, levels=order_list)

p <- locations %>%
  ggplot() +
  geom_rect(aes(xmin=position-1e3, xmax=position+1e3, ymax=0, ymin =10, fill=status_f)) +
  facet_wrap(query_chr ~ ., ncol=1, strip.position="right") + guides(scale="none") +
  xlab("Position (Mb)") +
  scale_x_continuous(labels=function(x)x/1e6, expand=c(0.005,0)) +
  scale_y_continuous(breaks=NULL) + labs(fill = "Reference contig") +
  theme(text = element_text(size=10), strip.text.y = element_text(angle = 0), strip.text.x = element_text(margin = margin(0,0,0,0, "cm")), panel.background = element_rect(fill = "white", colour = "black"), panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save results
ggsave(paste(as.character(opt$file), "_buscopainter.png", sep = ""), plot = p, width = 15, height = 30, units = "cm", device = "png")
pdf(NULL)
ggsave(paste(as.character(opt$file), "_buscopainter.pdf", sep = ""), plot = p, width = 15, height = 30, units = "cm", device = "pdf")


