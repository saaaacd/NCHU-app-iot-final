//
//  ScheduleVMTests.swift
//  appTests
//
//  Created by 劉李陽 on 2025/9/21.
//

import XCTest
@testable import app

@MainActor
final class ScheduleVMTests: XCTestCase {
    
    var viewModel: ScheduleVM!
    
    override func setUp() {
        super.setUp()
        viewModel = ScheduleVM()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Course Management Tests
    
    func testAddCourse() {
        let course = Course.sampleCourses[0]
        viewModel.addCourse(course)
        
        XCTAssertEqual(viewModel.courses.count, 1)
        XCTAssertEqual(viewModel.courses.first?.id, course.id)
    }
    
    func testRemoveCourse() {
        let course = Course.sampleCourses[0]
        viewModel.addCourse(course)
        viewModel.removeCourse(withID: course.id)
        
        XCTAssertEqual(viewModel.courses.count, 0)
    }
    
    // MARK: - Conflict Detection Tests
    
    func testConflictDetection_SameDayOverlappingPeriods() {
        let course1 = Course(
            name: "Course 1",
            dept: "Test",
            requiredType: .必修,
            dayOfWeek: 1,
            periods: [3, 4],
            weeks: [1, 2, 3],
            buildingCode: "Test",
            room: "101"
        )
        
        let course2 = Course(
            name: "Course 2",
            dept: "Test",
            requiredType: .選修,
            dayOfWeek: 1,
            periods: [4, 5],
            weeks: [1, 2, 3],
            buildingCode: "Test",
            room: "102"
        )
        
        let conflicts = viewModel.conflicts(in: [course1, course2])
        XCTAssertEqual(conflicts.count, 1)
    }
    
    func testConflictDetection_DifferentDays() {
        let course1 = Course(
            name: "Course 1",
            dept: "Test",
            requiredType: .必修,
            dayOfWeek: 1,
            periods: [3, 4],
            weeks: [1, 2, 3],
            buildingCode: "Test",
            room: "101"
        )
        
        let course2 = Course(
            name: "Course 2",
            dept: "Test",
            requiredType: .選修,
            dayOfWeek: 2,
            periods: [3, 4],
            weeks: [1, 2, 3],
            buildingCode: "Test",
            room: "102"
        )
        
        let conflicts = viewModel.conflicts(in: [course1, course2])
        XCTAssertEqual(conflicts.count, 0)
    }
    
    // MARK: - Free Slot Calculation Tests
    
    func testFreeSlots_EmptySchedule() {
        let freeSlots = viewModel.freeSlots(courses: [], on: 1, minLength: 2)
        XCTAssertEqual(freeSlots.count, 1)
        XCTAssertEqual(freeSlots.first, 1...14)
    }
    
    func testFreeSlots_WithCourses() {
        let course = Course(
            name: "Test Course",
            dept: "Test",
            requiredType: .必修,
            dayOfWeek: 1,
            periods: [3, 4, 5],
            weeks: [1, 2, 3],
            buildingCode: "Test",
            room: "101"
        )
        
        let freeSlots = viewModel.freeSlots(courses: [course], on: 1, minLength: 2)
        
        // Should have slots before (1-2) and after (6-14) the course
        XCTAssertTrue(freeSlots.contains(1...2))
        XCTAssertTrue(freeSlots.contains(6...14))
    }
}
