SUBDIRS = genmath z88math zxmath math48 cpcmath fastmath mbf32 mbf64 math32
CLEANDIRS = $(SUBDIRS:%=clean-%)

include ../Make.config
     
.PHONY: subdirs $(SUBDIRS) $(CLEANDIRS)
     
subdirs: $(SUBDIRS)
     
$(SUBDIRS):
	$(MAKE) -C $@

clean: $(CLEANDIRS)

$(CLEANDIRS): 
	$(MAKE) -C $(@:clean-%=%) clean
