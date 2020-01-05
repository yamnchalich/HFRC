INCLUDE = /usr/local/include
LIB = /usr/local/lib
CC = gcc
CFLAGS = -I$(INCLUDE2) -L$(LIB2) -c
LDFLAGS = -Wall -lm
SOURCES = convert.c
OBJECTS = $(SOURCES:.c=.o)
EXECUTABLE = convert

all: $(EXECUTABLE) clean

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS) 

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm $(OBJECTS) *~
