obj = monitor.o monitor_common.o monitor_others.o
target = monitord

CXXFLAGS= -g -pthread -std=c++17 -DHAVE_CONFIG_H -I. -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -O2 
LDFLAGS= -g -lstdc++fs -pie -Wl,-z,now 
LDLIBS= -lm -ldl -lpthread -ljson-c

all: $(obj)
	${CXX} ${LDFLAGS} -o $(target) $(obj) ${LDLIBS}

%.o:%.cpp
	${CXX} ${CXXFLAGS} -c $^ -o $@

simulation: $(obj:.o=.cpp)
	g++ -DTEST_SIMULATION -c $(obj:.o=.cpp) -o $(obj)
	g++ -o $(target) $(obj)

.PHONY: clean
clean:
	rm -rf $(obj) $(target)
