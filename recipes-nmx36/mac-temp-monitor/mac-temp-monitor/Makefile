obj = mac_temp_monitor.o 
target = mac_temp_monitord


# CXXPLAGS= -fPIE -pie -fstack-protector-all -D_FORTIFY_SOURCE=2 -O2 -g -pthread -std=c++17 -DHAVE_CONFIG_H -I.
# LDLLAGS= -g -lstdc++fs -fPIE -pie -Wl,-z,now
CXXPLAGS ?= $(CXXFLAGS) -fPIE -pie -fstack-protector-all -D_FORTIFY_SOURCE=2 -pthread -std=c++17 -DHAVE_CONFIG_H -I.
LDLLAGS ?= $(LDFLAGS) -lstdc++fs -fPIE -pie -Wl,-z,now
LDLIBS= -lm -ldl 

all: $(obj)
	${CXX} ${LDLLAGS} -o $(target) $(obj) ${LDLIBS}

%.o:%.c
	${CXX} ${CXXPLAGS} -c $^ -o $@

simulation: $(obj:.o=.c)
	g++ -DTEST_SIMULATION -c $(obj:.o=.c) -o $(obj)
	g++ -o $(target) $(obj)

.PHONY: clean
clean:
	rm -rf $(obj) $(target)
