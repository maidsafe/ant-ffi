<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\Chunk;
use AntFfi\Types\ChunkAddress;

final class DataTypesTest extends TestCase
{
    public function testChunkCreation(): void
    {
        $data = 'Test chunk data';
        $chunk = new Chunk($data);

        $this->assertEquals($data, $chunk->value());
    }

    public function testChunkAddress(): void
    {
        $chunk = new Chunk('Test data for addressing');
        $address = $chunk->address();

        $hex = $address->toHex();
        $this->assertNotEmpty($hex);
        $this->assertMatchesRegularExpression('/^[0-9a-f]+$/i', $hex);
    }

    public function testChunkAddressFromHex(): void
    {
        $chunk = new Chunk('Test data');
        $address1 = $chunk->address();
        $hex = $address1->toHex();

        $address2 = ChunkAddress::fromHex($hex);
        $this->assertEquals($hex, $address2->toHex());
    }

    public function testChunkSize(): void
    {
        $data = 'Test chunk data with some content';
        $chunk = new Chunk($data);

        $size = $chunk->size();
        $this->assertGreaterThan(0, $size);
    }

    public function testChunkIsNotTooBig(): void
    {
        $data = 'Small test data';
        $chunk = new Chunk($data);

        $this->assertFalse($chunk->isTooBig());
    }

    public function testSameDataProducesSameAddress(): void
    {
        $data = 'Identical data';
        $chunk1 = new Chunk($data);
        $chunk2 = new Chunk($data);

        $this->assertEquals($chunk1->address()->toHex(), $chunk2->address()->toHex());
    }

    public function testDifferentDataProducesDifferentAddress(): void
    {
        $chunk1 = new Chunk('Data one');
        $chunk2 = new Chunk('Data two');

        $this->assertNotEquals($chunk1->address()->toHex(), $chunk2->address()->toHex());
    }
}
