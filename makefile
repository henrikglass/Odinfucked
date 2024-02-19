all: debug

ODIN_PATH := /home/henrik/program/Odin

debug:
	$(ODIN_PATH)/odin build src -file -out:bfodin -o:minimal -debug

release:
	$(ODIN_PATH)/odin build src -file -out:bfodin -o:speed

clean:
	-rm bfodin	
