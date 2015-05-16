# -*- python -*-
'''
MIT/X Consortium License

Copyright © 2015  Mattias Andrée <maandree@member.fsf.org>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
'''

cimport cython

from libc.stdlib cimport malloc, free


cdef extern int bus_create(const char *, int, char **)
'''
Create a new bus

@param   file      The pathname of the bus, `NULL` to create a random one
@param   flags     `BUS_EXCL` (if `file` is not `NULL`) to fail if the file
                   already exists, otherwise if the file exists, nothing
                   will happen;
                   `BUS_INTR` to fail if interrupted
@param   out_file  Output parameter for the pathname of the bus
@return            0 on success, -1 on error
'''

cdef extern int bus_unlink(const char *)
'''
Remove a bus

@param   file  The pathname of the bus
@return        0 on success, -1 on error
'''

cdef extern int bus_open(long, const char *, int)
'''
Open an existing bus

@param   bus    Bus information to fill
@param   file   The filename of the bus
@param   flags  `BUS_RDONLY`, `BUS_WRONLY` or `BUS_RDWR`,
                the value must not be negative
@return         0 on success, -1 on error
'''

cdef extern int bus_close(long)
'''
Close a bus

@param   bus  Bus information
@return       0 on success, -1 on error
'''

cdef extern int bus_write(long, const char *, int)
'''
Broadcast a message a bus

@param   bus      Bus information
@param   message  The message to write, may not be longer than
                  `BUS_MEMORY_SIZE` including the NUL-termination
@param   flags    `BUS_NOWAIT` fail if other process is attempting
                  to write
@return           0 on success, -1 on error
'''

cdef extern int bus_read(long, int (*)(const char *, void *), void *)
'''
Listen (in a loop, forever) for new message on a bus

@param   bus       Bus information
@param   callback  Function to call when a message is received, the
                   input parameters will be the read message and
                   `user_data` from `bus_read`'s parameter with the
                   same name. The message must have been parsed or
                   copied when `callback` returns as it may be over
                   overridden after that time. `callback` should
                   return either of the the values:
                     0:  stop listening
                     1:  continue listening
                    -1:  an error has occurred
@return            0 on success, -1 on error
'''


def bus_allocate() -> int:
    '''
    Allocate memory for a bus
    
    @return  The address of the allocated memory
    '''
    n = 2 * sizeof(long long) + sizeof(int) + sizeof(char *)
    return <long>malloc(n)


def bus_deallocate(address : int):
    '''
    Deallocate memory for a bus
    
    @param  address  The address of the allocated memory
    '''
    free(<void *><long>address)


def bus_create_wrapped(file : str, flags : int) -> str:
    '''
    Create a new bus
    
    @param   file      The pathname of the bus, `None` to create a random one
    @param   flags     `BUS_EXCL` (if `file` is not `None`) to fail if the file
                       already exists, otherwise if the file exists, nothing
                       will happen;
                       `BUS_INTR` to fail if interrupted
    @return            The pathname of the bus, `None` on error;
                       `file` is returned unless `file` is `None`
    '''
    cdef const char* cfile
    cdef char* ofile
    cdef bytes bs
    if file is not None:
        bs = file.encode('utf-8') + bytes([0])
        cfile = bs
        r = bus_create(cfile, flags, <char **>NULL)
        return file if r == 0 else None
    r = bus_create(<char *>NULL, flags, &ofile)
    if r == 0:
        bs = ofile
        return bs.decode('utf-8', 'strict')
    return None


def bus_unlink_wrapped(file : str) -> int:
    '''
    Remove a bus
    
    @param   file  The pathname of the bus
    @return        0 on success, -1 on error
    '''
    cdef const char* cfile
    cdef bytes bs
    bs = file.encode('utf-8') + bytes([0])
    cfile = bs
    return bus_unlink(cfile)


def bus_open_wrapped(bus : int, file : str, flags : int) -> int:
    '''
    Open an existing bus
    
    @param   bus    Bus information to fill
    @param   file   The filename of the bus
    @param   flags  `BUS_RDONLY`, `BUS_WRONLY` or `BUS_RDWR`,
                    the value must not be negative
    @return         0 on success, -1 on error
    '''
    cdef const char* cfile
    cdef bytes bs
    bs = file.encode('utf-8') + bytes([0])
    cfile = bs
    return bus_open(<long>bus, cfile, <int>flags)


def bus_close_wrapped(bus : int) -> int:
    '''
    Close a bus
    
    @param   bus  Bus information
    @return       0 on success, -1 on error
    '''
    return bus_close(<long>bus)


def bus_write_wrapped(bus : int, message : str, flags : int) -> int:
    '''
    Broadcast a message a bus
    
    @param   bus      Bus information
    @param   message  The message to write, may not be longer than
                      `BUS_MEMORY_SIZE` including the NUL-termination
    @param   flags    `BUS_NOWAIT` fail if other process is attempting
                      to write
    @return           0 on success, -1 on error
    '''
    cdef const char* cmessage
    cdef bytes bs
    bs = message.encode('utf-8') + bytes([0])
    cmessage = bs
    return bus_write(<long>bus, cmessage, <int>flags)


cdef int bus_callback_wrapper(const char *message, user_data):
    cdef bytes bs
    callback, user_data = tuple(<object>user_data)
    if message is NULL:
        return <int>callback(None, user_data)
    else:
        bs = message
        return <int>callback(bs, user_data)


def bus_read_wrapped(bus : int, callback : callable, user_data) -> int:
    '''
    Listen (in a loop, forever) for new message on a bus
    
    @param   bus       Bus information
    @param   callback  Function to call when a message is received, the
                       input parameters will be the read message and
                       `user_data` from `bus_read`'s parameter with the
                       same name. The message must have been parsed or
                       copied when `callback` returns as it may be over
                       overridden after that time. `callback` should
                       return either of the the values:
                       0:  stop listening
                       1:  continue listening
                       -1:  an error has occurred
    @return           0 on success, -1 on error
    '''
    user = (callback, user_data)
    return bus_read(<long>bus, <int (*)(const char *, void *)>&bus_callback_wrapper, <void *>user)

