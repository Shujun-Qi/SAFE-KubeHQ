package prolog.terms
import scala.collection.mutable.LinkedHashMap

final class Cons(h: Term, b: Term)
  extends Fun(".", Array(h, b)) {

  def getHead = args(0).ref
  def getBody = args(1).ref

  override def safeCopy(): Fun = {
    new Cons(null, null)
  }

  override def toString =
    // Cons.to_string_raw({ x => x.toString }, this)
    Cons.to_string({ x => x.toString }, this)
}

object Cons {
  final def build(x: Term, y: Term) = new Cons(x, y)

  final def fromList(xs: List[Term]): Term = xs match {
    case Nil => Const.nil
    case _ => xs.foldRight[Term](Const.nil)(build)
  }

  final def fromIterator(xs: Iterator[Term]): Term = {
    //case Nil => Const.nil
    //case _ => xs.foldRight[Term](Const.nil)(build)
    if (!xs.hasNext) Const.nil
    else build(xs.next, fromIterator(xs))
  }

  final def toList(t: Term): List[Term] = t match {
    case Const.nil => Nil
    case x: Cons => x.getHead :: toList(x.getBody)
    //case x: Term => List(x)
  }

  def to_string(c: Cons, vmap: LinkedHashMap[Var, String]): String = {
    to_string( { x => x.toString }, c, vmap)
  }

  val numPattern = """-?(\d+)(\.\d+)?""".r
  val symPattern = """([a-z]\w*)""".r
  // val consPattern = """(^\[[_a-zA-Z][\w\s,]*\]$)""".r
  val consPattern = """(^\[.*\]$)""".r

  def elementToString(f: Term => String, e: Term, vmap: LinkedHashMap[Var, String]): String = {
    if(e.isInstanceOf[Var] && vmap.contains(e.asInstanceOf[Var])) { 
       vmap(e.asInstanceOf[Var]) 
    } else {
      val _t = f(e)
      _t match {
        case numPattern(t) => _t
        case symPattern(t) => _t
        case consPattern(t) => _t // println(s"Cons pattern matched: ${_t}"); scala.io.StdIn.readLine(); _t
        case _ => s"'${_t}'" // println(s"added single quotes: ${_t}   ${_t.getClass}"); scala.io.StdIn.readLine(); s"'${_t}'" 
      }
    }
  }

  def to_string(f: Term => String, c: Cons, 
                vmap: LinkedHashMap[Var, String] = LinkedHashMap[Var, String]()): String = {
    val s = new StringBuffer()
    s.append("[")
    var x: Term = c
    var more = true
    while (more) {
      val c: Cons = x.asInstanceOf[Cons]
      val h = c.getHead
      val t = elementToString(f, h, vmap) 
      s.append(t)
      x = c.getBody
      if (x.isInstanceOf[Cons])
        s.append(",")
      else {
        more = false
        // if (x != Const.nil) {
        // println(s"\n Last element in a list:   x=$x    x.getClass=${x.getClass}     list:${c}")
        if(!Const.isNil(x)) {
          // println(s"\n Not Nil:   x=$x    x.getClass=${x.getClass}     list=${c}")
          s.append("|")
          val tx = elementToString(f, x, vmap) 
          s.append(tx)
        }
      }
    }
    s.append("]")
    s.toString
  }

  def to_string_raw(f: Term => String, c: Cons) = {
    val s = new StringBuffer()
    s.append("[")
    var x: Term = c
    var more = true
    while (more) {
      val c: Cons = x.asInstanceOf[Cons]
      s.append(f(c.getHead))
      x = c.getBody
      if (x.isInstanceOf[Cons])
        s.append(",")
      else {
        more = false
        // if (x != Const.nil) {
        if (!Const.isNil(x)) {
          s.append("|")
          s.append(f(x))
        }
      }
    }
    s.append("]")
    s.toString
  }

}
