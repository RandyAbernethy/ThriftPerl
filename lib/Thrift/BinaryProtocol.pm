#
# Copyright (c) 2006- Facebook
# Distributed under the Thrift Software License
#
# See accompanying file LICENSE or visit the Thrift site at:
# http://developers.facebook.com/thrift/
#
#  package - thrift.protocol.binary
#  author  - T Jake Luciani <jakers@gmail.com>
#  author  - Mark Slee      <mcslee@facebook.com>
#

require 5.6.0;

use strict;
use warnings;

use Thrift;
use Thrift::Protocol;

use Bit::Vector;

#
# Binary implementation of the Thrift protocol.
#
package Thrift::BinaryProtocol;
use base('Thrift::Protocol');

sub new
{
    my $classname = shift;
    my $trans     = shift;
    my $self      = $classname->SUPER::new($trans);

    return bless($self,$classname);
}

sub writeMessageBegin
{
    my $self = shift;
    my ($name, $type, $seqid) = @_;

    return
        $self->writeString($name) +
        $self->writeByte($type) +
        $self->writeI32($seqid);
}

sub writeMessageEnd
{
    my $self = shift;
    return 0;
}

sub writeStructBegin{
    my $self = shift;
    my $name = shift;
    return 0;
}

sub writeStructEnd
{
    my $self = shift;
    return 0;
}

sub writeFieldBegin
{
    my $self = shift;
    my ($fieldName, $fieldType, $fieldId) = @_;

    return
        $self->writeByte($fieldType) +
        $self->writeI16($fieldId);
}

sub writeFieldEnd
{
    my $self = shift;
    return 0;
}

sub writeFieldStop
{
    my $self = shift;
    return $self->writeByte(TType::STOP);
}

sub writeMapBegin
{
    my $self = shift;
    my ($keyType, $valType, $size) = @_;

    return
        $self->writeByte($keyType) +
        $self->writeByte($valType) +
        $self->writeI32($size);
}

sub writeMapEnd
{
    my $self = shift;
    return 0;
}

sub writeListBegin
{
    my $self = shift;
    my ($elemType, $size) = @_;

    return
        $self->writeByte($elemType) +
        $self->writeI32($size);
}

sub writeListEnd
{
    my $self = shift;
    return 0;
}

sub writeSetBegin
{
    my $self = shift;
    my ($elemType, $size) = @_;

    return
        $self->writeByte($elemType) +
        $self->writeI32($size);
}

sub writeSetEnd
{
    my $self = shift;
    return 0;
}

sub writeBool
{
    my $self = shift;
    my $value = shift;

    my $data = pack('c', $value ? 1 : 0);
    $self->{trans}->write($data, 1);
    return 1;
}

sub writeByte
{
    my $self = shift;
    my $value= shift;

    my $data = pack('c', $value);
    $self->{trans}->write($data, 1);
    return 1;
}

sub writeI16
{
    my $self = shift;
    my $value= shift;

    my $data = pack('n', $value);
    $self->{trans}->write($data, 2);
    return 2;
}

sub writeI32
{
    my $self = shift;
    my $value= shift;

    my $data = pack('N', $value);
    $self->{trans}->write($data, 4);
    return 4;
}

sub writeI64
{
    my $self = shift;
    my $value= shift;
    my $data;

    my $vec;
    #stop annoying error
    $vec = Bit::Vector->new_Dec(64, $value);
    $data = pack 'NN', $vec->Chunk_Read(32, 32), $vec->Chunk_Read(32, 0);

    $self->{trans}->write($data, 8);

    return 8;
}


sub writeDouble
{
    my $self = shift;
    my $value= shift;

    my $data = pack('d', $value);
    $self->{trans}->write(scalar reverse($data), 8);
    return 8;
}

sub writeString{
    my $self = shift;
    my $value= shift;

    my $len = length($value);

    my $result = $self->writeI32($len);
    if ($len) {
        $self->{trans}->write($value,$len);
    }
    return $result + $len;
  }


#
#All references
#
sub readMessageBegin
{
    my $self = shift;
    my ($name, $type, $seqid) = @_;

    return
        $self->readString($name) +
        $self->readByte($type) +
        $self->readI32($seqid);
}

sub readMessageEnd
{
    my $self = shift;
    return 0;
}

sub readStructBegin
{
    my $self = shift;
    my $name = shift;

    $$name = '';

    return 0;
}

sub readStructEnd
{
    my $self = shift;
    return 0;
}

sub readFieldBegin
{
    my $self = shift;
    my ($name, $fieldType, $fieldId) = @_;

    my $result = $self->readByte($fieldType);

    if ($$fieldType == TType::STOP) {
      $$fieldId = 0;
      return $result;
    }

    $result += $self->readI16($fieldId);

    return $result;
}

sub readFieldEnd() {
    my $self = shift;
    return 0;
}

sub readMapBegin
{
    my $self = shift;
    my ($keyType, $valType, $size) = @_;

    return
        $self->readByte($keyType) +
        $self->readByte($valType) +
        $self->readI32($size);
}

sub readMapEnd()
{
    my $self = shift;
    return 0;
}

sub readListBegin
{
    my $self = shift;
    my ($elemType, $size) = @_;

    return
        $self->readByte($elemType) +
        $self->readI32($size);
}

sub readListEnd
{
    my $self = shift;
    return 0;
}

sub readSetBegin
{
    my $self = shift;
    my ($elemType, $size) = @_;

    return
        $self->readByte($elemType) +
        $self->readI32($size);
}

sub readSetEnd
{
    my $self = shift;
    return 0;
}

sub readBool
{
    my $self  = shift;
    my $value = shift;

    my $data = $self->{trans}->readAll(1);
    my @arr = unpack('c', $data);
    $$value = $arr[0] == 1;
    return 1;
}

sub readByte
{
    my $self  = shift;
    my $value = shift;

    my $data = $self->{trans}->readAll(1);
    my @arr = unpack('c', $data);
    $$value = $arr[0];
    return 1;
}

sub readI16
{
    my $self  = shift;
    my $value = shift;

    my $data  = $self->{trans}->readAll(2);

    my @arr   = unpack('n', $data);

    $$value = $arr[0];

    if ($$value > 0x7fff) {
      $$value = 0 - (($$value - 1) ^ 0xffff);
    }

    return 2;
}

sub readI32
{
    my $self = shift;
    my $value= shift;

    my $data = $self->{trans}->readAll(4);
    my @arr = unpack('N', $data);

    $$value = $arr[0];
    if ($$value > 0x7fffffff) {
      $$value = 0 - (($$value - 1) ^ 0xffffffff);
    }
    return 4;
}

sub readI64
{
    my $self  = shift;
    my $value = shift;

    my $data = $self->{trans}->readAll(8);

    my ($hi,$lo)=unpack('NN',$data);

    my $vec = new Bit::Vector(64);

    $vec->Chunk_Store(32,32,$hi);
    $vec->Chunk_Store(32,0,$lo);

    $$value = $vec->to_Dec();

    return 8;
}

sub readDouble
{
    my $self  = shift;
    my $value = shift;

    my $data = scalar reverse($self->{trans}->readAll(8));
    my @arr = unpack('d', $data);

    $$value = $arr[0];

    return 8;
}

sub readString
{
    my $self  = shift;
    my $value = shift;

    my $len;
    my $result = $self->readI32(\$len);

    if ($len) {
      $$value = $self->{trans}->readAll($len);
    } else {
      $$value = '';
    }

    return $result + $len;
}

#
# Binary Protocol Factory
#
package TBinaryProtocolFactory;
use base('TProtocolFactory');

sub new
{
    my $classname = shift;
    my $self      = $classname->SUPER::new();

    return bless($self,$classname);
}

sub getProtocol{
    my $self  = shift;
    my $trans = shift;

    return new TBinaryProtocol($trans);
}

1;
