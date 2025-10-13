package com.maidsafe.core

import uniffi.autonomi.BinaryOperator
import uniffi.autonomi.ComputationException

class SafeMultiply : BinaryOperator {
  override fun perform(lhs: Long, rhs: Long): Long {
    try {
      return Math.multiplyExact(lhs, rhs)
    } catch (e: ArithmeticException) {
      throw ComputationException.Overflow()
    }
  }
}
