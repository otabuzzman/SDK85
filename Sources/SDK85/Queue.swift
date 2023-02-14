class Queue<T> {
    private var queue = List<T>()

    var isEmpty: Bool {
        return queue.isEmpty
    }

    func enqueue(_ element: T) {
        queue.append(value: element)
    }

    func dequeue() -> T? {
        guard
            !queue.isEmpty,
            let element = queue.first
        else {
            return nil
        }
        queue.remove(node: element)
        return element.value
    }

    func peek() -> T? {
        return queue.first?.value
    }

    func removeAll() {
        queue.removeAll()
    }
}

extension Queue: CustomStringConvertible {
    public var description: String {
        return queue.description
    }
}

class List<T> {
    private var head: Node<T>?
    private var tail: Node<T>?

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
    }

    func removeAll() {
        head = nil
        tail = nil
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
