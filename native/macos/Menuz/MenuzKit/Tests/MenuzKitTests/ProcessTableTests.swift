import Testing

@testable import MenuzKit

/// The process tree a stopped shell takes with it.
@Suite("Process table")
struct ProcessTableTests {
  static let ps = """
        1     0
      100     1
      200   100
      201   100
      300   200
      400     1
    junk line
      500   300
    """

  @Test("every descendant, children before grandchildren, and nothing outside the tree")
  func descendants() {
    #expect(ProcessTable.descendants(of: 100, in: Self.ps) == [200, 201, 300, 500])
  }

  @Test("a process with no children has no descendants, and an unknown one none either")
  func none() {
    #expect(ProcessTable.descendants(of: 400, in: Self.ps) == [])
    #expect(ProcessTable.descendants(of: 999, in: Self.ps) == [])
  }

  @Test("a loop in the table cannot hang the walk")
  func loop() {
    #expect(ProcessTable.descendants(of: 1, in: "2 1\n3 2\n2 3\n") == [2, 3])
  }
}
