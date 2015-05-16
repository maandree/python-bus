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
from posix.types cimport uid_t, gid_t, mode_t


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

cdef extern int bus_poll_start(long, int)
'''
Announce that the thread is listening on the bus.
This is required so the will does not miss any
messages due to race conditions. Additionally,
not calling this function will cause the bus the
misbehave, is `bus_poll` is written to expect
this function to have been called.

@param   bus    Bus information
@param   flags  `BUS_NOWAIT` if the bus should fail and set `errno` to
                `EAGAIN` if there isn't already a message available on
                the bus when `bus_poll` is called
@return         0 on success, -1 on error
'''

cdef extern int bus_poll_stop(long)
'''
Announce that the thread has stopped listening on the bus.
This is required so that the thread does not cause others
to wait indefinitely.

@param   bus  Bus information
@return       0 on success, -1 on error
'''

cdef extern const char *bus_poll(long)
'''
Wait for a message to be broadcasted on the bus.
The caller should make a copy of the received message,
without freeing the original copy, and parse it in a
separate thread. When the new thread has started be
started, the caller of this function should then
either call `bus_poll` again or `bus_poll_stop`.

@param   bus  Bus information
@return       The received message, `NULL` on error
'''

cdef extern int bus_chown(const char *, uid_t, gid_t)
'''
Change the ownership of a bus

`stat(2)` can be used of the bus's associated file to get the bus's ownership

@param   file   The pathname of the bus
@param   owner  The user ID of the bus's new owner
@param   group  The group ID of the bus's new group
@return         0 on success, -1 on error
'''

cdef extern int bus_chmod(const char *, mode_t)
'''
Change the permissions for a bus

`stat(2)` can be used of the bus's associated file to get the bus's permissions

@param   file  The pathname of the bus
@param   mode  The permissions of the bus, any permission for a user implies
               full permissions for that user, except only the owner may
               edit the bus's associated file
@return        0 on success, -1 on error
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
    @param   flags    `BUS_NOWAIT` fail with errno set to `os.errno.EAGAIN`
                      if other process is attempting to write
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


def bus_poll_start_wrapped(bus : int, flags : int) -> int:
    '''
    Announce that the thread is listening on the bus.
    This is required so the will does not miss any
    messages due to race conditions. Additionally,
    not calling this function will cause the bus the
    misbehave, is `bus_poll_wrapped` is written to expect
    this function to have been called.
    
    @param   bus    Bus information
    @param   flags  `BUS_NOWAIT` if the bus should fail and set `errno` to
                    `os.errno.EAGAIN` if there isn't already a message
                    available on
                    the bus when `bus_poll` is called
    @return         0 on success, -1 on error
    '''
    return bus_poll_start(<long>bus, <int>flags)


def bus_poll_stop_wrapped(bus : int) -> int:
    '''
    Announce that the thread has stopped listening on the bus.
    This is required so that the thread does not cause others
    to wait indefinitely.
    
    @param   bus  Bus information
    @return       0 on success, -1 on error
    '''
    return bus_poll_stop(<long>bus)


def bus_poll_wrapped(bus : int) -> bytes:
    '''
    Wait for a message to be broadcasted on the bus.
    The caller should make a copy of the received message,
    without freeing the original copy, and parse it in a
    separate thread. When the new thread has started be
    started, the caller of this function should then
    either call `bus_poll_wrapped` again or
    `bus_poll_stop_wrapped`.
    
    @param   bus  Bus information
    @return       The received message, `None` on error
    '''
    cdef const char* msg
    cdef bytes bs
    msg = bus_poll(<long>bus)
    if msg is NULL:
        return None
    bs = msg
    return bs


def bus_chown_wrapped(file : str, owner : int, group : int) -> int:
    '''
    Change the ownership of a bus
    
    `os.stat` can be used of the bus's associated file to get the bus's ownership
    
    @param   file   The pathname of the bus
    @param   owner  The user ID of the bus's new owner
    @param   group  The group ID of the bus's new group
    @return         0 on success, -1 on error
    '''
    cdef const char* cfile
    cdef bytes bs
    bs = file.encode('utf-8') + bytes([0])
    cfile = bs
    return bus_chown(cfile, <uid_t>owner, <gid_t>group)


def bus_chmod_wrapped(file : str, mode : int) -> int:
    '''
    Change the permissions for a bus
    
    `os.stat` can be used of the bus's associated file to get the bus's permissions
    
    @param   file  The pathname of the bus
    @param   mode  The permissions of the bus, any permission for a user implies
                   full permissions for that user, except only the owner may
                   edit the bus's associated file
    @return        0 on success, -1 on error
    '''
    cdef const char* cfile
    cdef bytes bs
    bs = file.encode('utf-8') + bytes([0])
    cfile = bs
    return bus_chmod(cfile, <mode_t>mode)

