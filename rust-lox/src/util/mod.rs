pub struct DoublePeeker<I: Iterator> {
  first_peeked: Option<Option<I::Item>>,
  second_peeked: Option<Option<I::Item>>,
  iter: I,
}

impl<I: Iterator> DoublePeeker<I>
where
  I::Item: std::fmt::Debug + Copy,
{
  pub fn new(iter: I) -> Self {
    DoublePeeker {
      iter,
      first_peeked: None,
      second_peeked: None,
    }
  }

  pub fn peek(&mut self) -> Option<I::Item> {
    self.first_peeked.get_or_insert_with(|| self.iter.next());
    self.first_peeked.unwrap()
  }

  pub fn peek_next(&mut self) -> Option<I::Item> {
    self.first_peeked.get_or_insert_with(|| self.iter.next());
    self.second_peeked.get_or_insert_with(|| self.iter.next());

    self.second_peeked.unwrap()
  }
}

impl<I: Iterator> Iterator for DoublePeeker<I> {
  type Item = I::Item;

  fn next(&mut self) -> Option<Self::Item> {
    let next_value = match self.first_peeked.take() {
      Some(value) => value,
      None => self.iter.next(),
    };

    self.first_peeked = self.second_peeked.take();

    next_value
  }
}

#[cfg(test)]
mod tests_double_peekable {
  use super::*;

  #[test]
  fn test_next() {
    let vec = Vec::from([1, 2, 3, 4, 5]);
    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
  }

  #[test]
  fn test_peek() {
    let vec = Vec::from([1, 2, 3, 4, 5]);
    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.peek());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
  }

  #[test]
  fn test_peek_next() {
    let vec = Vec::from([1, 2, 3, 4, 5]);

    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.peek());
    assert_eq!(Some(&5), double_peeker.peek_next());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.next());
  }

  #[test]
  fn test_peek_none() {
    let vec = Vec::from([1, 2, 3, 4, 5]);

    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&1), double_peeker.next());
    assert_eq!(Some(&2), double_peeker.next());
    assert_eq!(Some(&3), double_peeker.next());
    assert_eq!(Some(&4), double_peeker.next());
    assert_eq!(Some(&5), double_peeker.next());
    assert_eq!(None, double_peeker.peek());
    assert_eq!(None, double_peeker.peek_next());
    assert_eq!(None, double_peeker.next());
  }

  #[test]
  fn test_peek_strings() {
    let vec = Vec::from(["a", "b", "c", "d", "e"]);

    let mut double_peeker = DoublePeeker::new(vec.iter());

    assert_eq!(Some(&"a"), double_peeker.next());
    assert_eq!(Some(&"b"), double_peeker.next());
    assert_eq!(Some(&"c"), double_peeker.next());
    assert_eq!(Some(&"d"), double_peeker.peek());
    assert_eq!(Some(&"e"), double_peeker.peek_next());
    assert_eq!(Some(&"d"), double_peeker.next());
    assert_eq!(None, double_peeker.peek_next());
    assert_eq!(Some(&"e"), double_peeker.next());
    assert_eq!(None, double_peeker.next());
  }
}
