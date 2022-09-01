class Queue<T> {
    private var list = List<T>()

    var isEmpty: Bool {
        return list.isEmpty
    }
    var count: Int {
        return list.count
    }

    func enqueue(_ element: T) {
        list.append(value: element)
    }

    func dequeue() -> T? {
        guard
            !list.isEmpty,
            let element = list.first
        else {
            return nil
        }
        list.remove(node: element)
        return element.value
    }

    func peek() -> T? {
        return list.first?.value
    }
}

class List<T> {
    private var head: Node<T>?
    private var tail: Node<T>?
    private(set) var count = 0

    var isEmpty: Bool {
        return head == nil // && count == 0
    }
    var first: Node<T>? {
        return head
    }
    var last: Node<T>? {
        return tail
    }

    func append(value: T) {
        let newNode = Node<T>(value: value)
        if let tailNode = tail {
            tailNode.next = newNode
            newNode.previous = tailNode
        } else {
            head = newNode
        }
        tail = newNode
        count += 1
    }

    func nodeAt(index: Int) -> Node<T>? {
        if index >= 0 {
            var node = head
            var i = index
            while node != nil {
                if i == 0 {
                    return node
                }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }

    func remove(node: Node<T>) {
        let prev = node.previous
        let next = node.next

        if let prev = prev {
            prev.next = next
        } else { 
            head = next
        }
        next?.previous = prev

        if next == nil { 
            tail = prev
        }

        node.previous = nil 
        node.next = nil
        count -= 1
    }

    func removeAll() {
        head = nil
        tail = nil
        count = 0
    }
}

extension List: CustomStringConvertible {
    public var description: String {
        var text = "["
        var node = head
        while node != nil {
            text += "\(node!.value)"
            node = node!.next
            if node != nil {
                text += ", "
            }
        }
        text += "]"
        return text
    }
}

class Node<T> {
    var value: T

    weak var next: Node<T>?
    var previous: Node<T>?

    init(value: T) {
        self.value = value
    }
}
