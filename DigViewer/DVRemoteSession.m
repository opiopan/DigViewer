//
//  DVRemoteSession.m
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteSession.h"

enum StreamStatus{StreamStandBy, StreamHead, StreamData};
static const size_t HEADER_LENGTH = sizeof(int) * 2;
static NSString* QUE_ELEMENT_COMMAND = @"command";
static NSString* QUE_ELEMENT_DATA = @"data";

@implementation DVRemoteSession{
    NSInputStream* _inputStream;
    BOOL _inputStreamHasBeenScheduled;
    NSOutputStream* _outputStream;
    BOOL _outputStreamHasBeenScheduled;
    NSRunLoop* _runLoop;

    NSMutableArray* _sendQue;
    enum StreamStatus _senderStatus;
    DVRCommand _sendingCommand;
    NSData* _sendingData;
    NSInteger _sendLength;
    
    enum StreamStatus _recieverStatus;
    UInt8 _recievingBufferHead[HEADER_LENGTH];
    UInt8* _recievingBuffer;
    int _recievingBufferSize;
    DVRCommand _recievingCommand;
    NSInteger _recievedLength;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    self = [self init];
    if (self){
        _inputStream = inputStream;
        _inputStream.delegate = self;
        _inputStreamHasBeenScheduled = NO;
        _outputStream = outputStream;
        _outputStream.delegate = self;
        _outputStreamHasBeenScheduled = NO;
        _senderStatus = StreamStandBy;
        _recieverStatus = StreamStandBy;
        _sendQue = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    
}

//-----------------------------------------------------------------------------------------
// ストリーム起動
//-----------------------------------------------------------------------------------------
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop
{
    _runLoop = runLoop;
    [self updateSenderStatus];
    [self updateRecieverStatus];
    [_inputStream open];
    [_outputStream open];
}

//-----------------------------------------------------------------------------------------
// クローズ
//-----------------------------------------------------------------------------------------
- (void)close
{
    [_inputStream close];
    [_inputStream removeFromRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
    _inputStreamHasBeenScheduled = NO;
    if (_recievingBuffer){
        free(_recievingBuffer);
        _recievingBuffer = nil;
    }
    [_outputStream close];
    [_outputStream removeFromRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
    _outputStreamHasBeenScheduled = NO;
}

//-----------------------------------------------------------------------------------------
// 送信キューへのコマンド追加
//-----------------------------------------------------------------------------------------
- (void)sendCommand:(DVRCommand)command withData:(NSData *)data replacingQue:(BOOL)isReplacingQue
{
    NSDictionary* entry = data ? @{QUE_ELEMENT_COMMAND: @(command), QUE_ELEMENT_DATA: data} : @{QUE_ELEMENT_COMMAND: @(command)};
    if (isReplacingQue){
        [_sendQue removeLastObject];
    }
    [_sendQue addObject:entry];
    [self updateSenderStatus];
}

//-----------------------------------------------------------------------------------------
// ストリームイベントの処理
//-----------------------------------------------------------------------------------------
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            [self recieveFromStream];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self sendToStream];
            break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
            [self performErrorForStream:stream];
            break;
        default:
            break;
    }
}

//-----------------------------------------------------------------------------------------
// senderの実装
//-----------------------------------------------------------------------------------------
- (void)updateSenderStatus
{
    if (_runLoop){
        if (_senderStatus == StreamHead && _sendLength >= HEADER_LENGTH){
            _sendLength = 0;
            _senderStatus = _sendingData ? StreamData : StreamStandBy;
        }
        if (_senderStatus == StreamData && _sendLength >= _sendingData.length){
            _sendLength = 0;
            _sendingData = nil;
            _senderStatus = StreamStandBy;
        }
        if (_senderStatus == StreamStandBy && _sendQue.count){
            NSDictionary* target = _sendQue[0];
            [_sendQue removeObjectAtIndex:0];
            _sendingCommand = [[target valueForKey:QUE_ELEMENT_COMMAND] intValue];
            _sendingData = [target valueForKey:QUE_ELEMENT_DATA];
            _sendLength = 0;
            _senderStatus = StreamHead;
        }

        if (_senderStatus == StreamStandBy && _outputStreamHasBeenScheduled){
            [_outputStream removeFromRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
            _outputStreamHasBeenScheduled = NO;
        }else if (_senderStatus != StreamStandBy && !_outputStreamHasBeenScheduled){
            [_outputStream scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
            _outputStreamHasBeenScheduled = YES;
        }
    }
}

- (void)sendToStream
{
    if (_senderStatus == StreamHead){
        UInt8 header[HEADER_LENGTH];
        *(int*)header = htonl(_sendingCommand);
        *(int*)(header + sizeof(int)) = htonl(_sendingData ? _sendingData.length : 0);
        NSInteger rc = [_outputStream write:header + _sendLength maxLength:HEADER_LENGTH - _sendLength];
        if (rc < 0){
            [self performErrorForStream:_outputStream];
            return;
        }
        _sendLength += rc;
        [self updateSenderStatus];
    }
    
    if (_senderStatus == StreamData){
        NSInteger rc = [_outputStream write:((UInt8*)_sendingData.bytes) + _sendLength
                                  maxLength:_sendingData.length - _sendLength];
        if (rc < 0){
            [self performErrorForStream:_outputStream];
            return ;
        }
        _sendLength += rc;
        [self updateSenderStatus];
    }
}

//-----------------------------------------------------------------------------------------
// recieverの実装
//-----------------------------------------------------------------------------------------
- (void)updateRecieverStatus
{
    if (_runLoop){
        if(_recieverStatus == StreamHead && _recievedLength >= HEADER_LENGTH){
            _recievingCommand = ntohl(*(int*)_recievingBufferHead);
            _recievingBufferSize = ntohl(*(int*)(_recievingBufferHead + sizeof(int)));
            if (_recievingBufferSize > 0){
                _recievingBuffer = malloc(_recievingBufferSize);
            }
            _recievedLength = 0;
            _recieverStatus = StreamData;
        }
        if (_recieverStatus == StreamData && _recievedLength >= _recievingBufferSize){
            NSData* data = nil;
            if (_recievingBuffer){
                data = [[NSData alloc] initWithBytesNoCopy:_recievingBuffer length:_recievingBufferSize
                                               deallocator:^(void* bytes, NSUInteger length){free(bytes);}];
            }
            _recievingBuffer = nil;
            _recievingBufferSize = 0;
            _recievedLength = 0;
            _recieverStatus = StreamStandBy;
            if (_delegate){
                [_delegate dvrSession:self recieveCommand:_recievingCommand withData:data];
            }
        }
        
        if (!_inputStreamHasBeenScheduled){
            [_inputStream scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
            _inputStreamHasBeenScheduled = YES;
        }
    }
}

- (void)recieveFromStream
{
    if (_recieverStatus == StreamStandBy){
        _recievedLength = 0;
        _recieverStatus = StreamHead;
    }
    
    if (_recieverStatus == StreamHead){
        NSInteger rc = [_inputStream read:_recievingBufferHead + _recievedLength maxLength:HEADER_LENGTH - _recievedLength];
        if (rc < 0){
            [self performErrorForStream:_inputStream];
            return;
        }
        _recievedLength += rc;
        [self updateRecieverStatus];
    }
    
    if (_recieverStatus == StreamData){
        NSInteger rc = [_inputStream read:_recievingBuffer + _recievedLength maxLength:_recievingBufferSize - _recievedLength];
        if (rc < 0){
            [self performErrorForStream:_inputStream];
            return;
        }
        _recievedLength += rc;
        [self updateRecieverStatus];
    }
}

//-----------------------------------------------------------------------------------------
// エラー処理
//-----------------------------------------------------------------------------------------
- (void)performErrorForStream:(NSStream*)stream
{
    if (_delegate){
        [_delegate drvSession:self shouldBeClosedByCause:stream.streamError];
    }
}

@end
