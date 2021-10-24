struct DoublePeekable<I: Iterator> {
  iter: I,
  first_peeked: Option<Option<I: Item>>,
  second_peeked: Option<Option<I: Item>>,
}

impl<I: Iterator> DoublePeekable<I> {
  pub(in crate::iter) fn new(iter: I) -> DoublePeekable<I> {
    DoublePeekable {
      iter,
      first_peeked: None,
      second_peeked: None,
    }
  }
}

impl<I: Iterator> Iterator for DoublePeekable<I> {
  type Item = I::Item;

  pub fn next(&mut self) -> Option<I::Item> {
    match self.second_peeked.take() {
      Some(v) => v,
      None => match self.first_peeked.take() {
        Some(v) => v,
        None => self.iter.next(),
      },
    }
  }

  pub fn peek(&mut self) -> Option<&I::Item> {
    let iter = &mut self.iter;
    self
      .first_peeked
      .get_or_insert_with(|| iter.next())
      .as_ref()
  }

  pub fn peek_next(&mut self) -> Option<&I::Item> {
    let iter = &mut self.iter;
    self.peek();
    self
      .second_peeked
      .get_or_insert_with(|| iter.next())
      .as_ref()
  }
}

#[cgf(test)]
mod tests {
  use super::*;

  #[test]
  fn test_double_peekable() {
    assert_eq!(true, false);
  }
}
