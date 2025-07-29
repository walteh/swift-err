import Atomics

private let _storeCallerInfo = ManagedAtomic<Bool>(true)

public func enableCallerInfo() {
	_storeCallerInfo.store(true, ordering: .relaxed)
}

public func disableCallerInfo() {
	_storeCallerInfo.store(false, ordering: .relaxed)
}

public func shouldStoreCallerInfo() -> Bool {
	_storeCallerInfo.load(ordering: .relaxed)
}
